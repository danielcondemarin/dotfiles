import type {
  AgentEndEvent,
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import {
  classifyChecks,
  formatChecks,
  type CheckClassification,
  type PullRequest,
  type RequiredCheck,
} from "./state.ts";
import {
  parsePullRequestUrls,
  repoFromGitRemote,
  trackedPrKey,
  type TrackedPr,
} from "./tracker.ts";

const STATUS_KEY = "ci-gate";
const TRACKED_PR_ENTRY = "ci-gate-tracked-pr";
const BLOCKER_ENTRY = "ci-gate-external-blocker";
const REQUIRED_CHECK_REPORTING = "required-check-reporting";
const CREATION_SUCCESS_MARKER = "__PI_CI_GATE_CREATE_OK__=";
const DEFAULT_POLL_MS = 30_000;
const DEFAULT_MAX_POLL_MS = 120_000;
const DEFAULT_STALL_MS = 10 * 60_000;
const DEFAULT_DISCOVERY_MS = 2 * 60_000;
const EXTERNAL_CATEGORIES = [
  "base_branch_failure",
  "ci_service_outage",
  "permission_or_authentication",
  "required_check_misconfiguration",
  "external_dependency",
  "other",
] as const;

interface TrackedPrEntry {
  action: "add" | "remove";
  pr: TrackedPr;
}

interface BlockerEvidence {
  checkName: string;
  url: string;
  observation: string;
}

interface ExternalBlocker {
  active: boolean;
  repo: string;
  prNumber: number;
  headSha: string;
  category: (typeof EXTERNAL_CATEGORIES)[number];
  reason: string;
  evidence: BlockerEvidence[];
  blockingFingerprint: string;
  reportedAt: string;
}

interface ReleaseEligibility {
  repo: string;
  prNumber: number;
  headSha: string;
  condition: "failed" | "stalled-pending" | "stalled-unreported" | "inspection-error";
  checkNames: string[];
  blockingFingerprint: string;
}

interface PollState {
  headSha: string;
  classificationKind: CheckClassification["kind"];
  fingerprint?: string;
  unchangedSince: number;
  discoverySince: number;
}

type Inspection =
  | { kind: "inactive"; tracked: TrackedPr; reason: string; pr?: PullRequest }
  | { kind: "error"; tracked: TrackedPr; reason: string; pr?: PullRequest }
  | { kind: "local-checkout-error"; tracked: TrackedPr; reason: string; pr: PullRequest }
  | { kind: "local-head-mismatch"; tracked: TrackedPr; reason: string; pr: PullRequest; localHead: string }
  | { kind: "active"; tracked: TrackedPr; pr: PullRequest; classification: CheckClassification };

interface ActionableInspection {
  inspection: Inspection;
  cause: string;
}

function positiveDuration(name: string, fallback: number): number {
  const parsed = Number.parseInt(process.env[name] ?? "", 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function isEnabled(): boolean {
  const value = (process.env.PI_CI_GATE ?? "1").toLowerCase();
  return value !== "0" && value !== "false" && value !== "off";
}

function parseJson<T>(value: string): T | undefined {
  try {
    return JSON.parse(value) as T;
  } catch {
    return undefined;
  }
}

function commandFailure(command: string, stderr: string): string {
  return `${command} failed: ${stderr.trim() || "no error output"}`;
}

function sleep(ms: number, keepWaiting: () => boolean): Promise<void> {
  return new Promise((resolve) => {
    let settled = false;
    let interval: ReturnType<typeof setInterval>;
    const finish = () => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      clearInterval(interval);
      resolve();
    };
    const timer = setTimeout(finish, ms);
    interval = setInterval(() => {
      if (!keepWaiting()) finish();
    }, Math.min(ms, 1_000));
  });
}

function assistantStopReason(event: AgentEndEvent): string | undefined {
  const assistant = [...event.messages].reverse().find((message) => message.role === "assistant");
  return assistant?.role === "assistant" ? assistant.stopReason : undefined;
}

function blockingCheckNames(classification: CheckClassification): string[] {
  if (classification.kind === "unreported") return [REQUIRED_CHECK_REPORTING];
  return classification.checks
    .filter((check) => check.bucket.toLowerCase() !== "pass")
    .map((check) => check.name)
    .sort();
}

function blockingFingerprint(classification: CheckClassification): string {
  if (classification.kind === "unreported") return REQUIRED_CHECK_REPORTING;
  return JSON.stringify(
    classification.checks
      .filter((check) => check.bucket.toLowerCase() !== "pass")
      .map((check) => [check.name, check.state, check.bucket, check.link, check.description])
      .sort((left, right) => left[0].localeCompare(right[0])),
  );
}

function inspectionErrorFingerprint(reason: string): string {
  return `inspection-error:${reason.trim().replace(/\s+/g, " ")}`;
}

function validEvidenceUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:";
  } catch {
    return false;
  }
}

function looksLikePrCreation(command: string): boolean {
  let candidate = command.trim();
  const leadingCd = candidate.match(/^cd\s+(?:"[^"]+"|'[^']+'|[^;&|]+?)\s*&&\s*/);
  if (leadingCd) candidate = candidate.slice(leadingCd[0].length).trim();
  if (!/^gh\s+pr\s+create\b/.test(candidate)) return false;
  return !/[;&|\r\n]/.test(candidate);
}

function wrapPrCreationCommand(command: string): string {
  return [
    "(",
    command,
    "__pi_ci_gate_status=$?",
    `if [ "$__pi_ci_gate_status" -eq 0 ]; then printf '\\n${CREATION_SUCCESS_MARKER}%s\\n' "$PWD"; fi`,
    'exit "$__pi_ci_gate_status"',
    ")",
  ].join("\n");
}

function creationCheckoutPath(output: string): string | undefined {
  const line = output
    .split("\n")
    .reverse()
    .find((candidate) => candidate.startsWith(CREATION_SUCCESS_MARKER));
  const path = line?.slice(CREATION_SUCCESS_MARKER.length).trim();
  return path || undefined;
}

function isTrackedPr(value: unknown): value is TrackedPr {
  if (!value || typeof value !== "object") return false;
  const pr = value as Partial<TrackedPr>;
  return (
    typeof pr.repo === "string" &&
    pr.repo.includes("/") &&
    Number.isInteger(pr.number) &&
    (pr.number ?? 0) > 0 &&
    typeof pr.url === "string" &&
    validEvidenceUrl(pr.url) &&
    (pr.checkoutPath === undefined || typeof pr.checkoutPath === "string")
  );
}

function isTrackedPrEntry(value: unknown): value is TrackedPrEntry {
  if (!value || typeof value !== "object") return false;
  const entry = value as Partial<TrackedPrEntry>;
  return (entry.action === "add" || entry.action === "remove") && isTrackedPr(entry.pr);
}

function isExternalBlocker(value: unknown): value is ExternalBlocker {
  if (!value || typeof value !== "object") return false;
  const blocker = value as Partial<ExternalBlocker>;
  if (
    blocker.active === false &&
    typeof blocker.repo === "string" &&
    Number.isInteger(blocker.prNumber)
  ) {
    return true;
  }
  return Boolean(
    blocker.active === true &&
      typeof blocker.repo === "string" &&
      Number.isInteger(blocker.prNumber) &&
      typeof blocker.headSha === "string" &&
      blocker.headSha.length >= 7 &&
      typeof blocker.category === "string" &&
      (EXTERNAL_CATEGORIES as readonly string[]).includes(blocker.category) &&
      typeof blocker.reason === "string" &&
      blocker.reason.trim().length >= 10 &&
      Array.isArray(blocker.evidence) &&
      blocker.evidence.length > 0 &&
      typeof blocker.blockingFingerprint === "string" &&
      blocker.blockingFingerprint.length > 0 &&
      blocker.evidence.every(
        (item) =>
          typeof item.checkName === "string" &&
          item.checkName.trim().length > 0 &&
          validEvidenceUrl(item.url) &&
          typeof item.observation === "string" &&
          item.observation.trim().length >= 10,
      ),
  );
}

function blockerCovers(
  blocker: ExternalBlocker,
  pr: PullRequest,
  checkNames: string[],
  fingerprint: string,
): boolean {
  const covered = new Set(blocker.evidence.map((item) => item.checkName));
  return (
    blocker.active &&
    blocker.headSha === pr.headRefOid &&
    blocker.blockingFingerprint === fingerprint &&
    checkNames.every((name) => covered.has(name))
  );
}

function inspectionSummary(inspection: Inspection): string {
  const identity = `${inspection.tracked.repo}#${inspection.tracked.number}`;
  if (
    inspection.kind === "inactive" ||
    inspection.kind === "error" ||
    inspection.kind === "local-checkout-error" ||
    inspection.kind === "local-head-mismatch"
  ) {
    return `${identity}: ${inspection.reason}`;
  }
  return `${identity}: ${inspection.classification.kind}\n${formatChecks(inspection.classification.checks)}`;
}

export default function ciGate(pi: ExtensionAPI) {
  const pollMs = positiveDuration("PI_CI_GATE_POLL_MS", DEFAULT_POLL_MS);
  const maxPollMs = positiveDuration("PI_CI_GATE_MAX_POLL_MS", DEFAULT_MAX_POLL_MS);
  const stallMs = positiveDuration("PI_CI_GATE_STALL_MS", DEFAULT_STALL_MS);
  const discoveryMs = positiveDuration("PI_CI_GATE_DISCOVERY_MS", DEFAULT_DISCOVERY_MS);
  const gitCommand = process.env.PI_CI_GATE_GIT || "git";
  const ghCommand = process.env.PI_CI_GATE_GH || "gh";

  let sessionAlive = false;
  let monitoring = false;
  let recheckTimer: ReturnType<typeof setTimeout> | undefined;
  const creationCalls = new Set<string>();
  const trackedPrs = new Map<string, TrackedPr>();
  const blockers = new Map<string, ExternalBlocker>();
  const eligibility = new Map<string, ReleaseEligibility>();
  const pollStates = new Map<string, PollState>();

  function registerPr(pr: TrackedPr, persist = true): boolean {
    const key = trackedPrKey(pr);
    const existing = trackedPrs.get(key);
    if (existing) {
      if (pr.checkoutPath && existing.checkoutPath !== pr.checkoutPath) {
        const updated = { ...existing, checkoutPath: pr.checkoutPath };
        trackedPrs.set(key, updated);
        if (persist) {
          pi.appendEntry(
            TRACKED_PR_ENTRY,
            { action: "add", pr: updated } satisfies TrackedPrEntry,
          );
        }
      }
      return false;
    }
    trackedPrs.set(key, pr);
    if (persist) {
      pi.appendEntry(TRACKED_PR_ENTRY, { action: "add", pr } satisfies TrackedPrEntry);
    }
    return true;
  }

  function removePr(pr: TrackedPr, persist = true): boolean {
    const key = trackedPrKey(pr);
    if (!trackedPrs.delete(key)) return false;
    blockers.delete(key);
    eligibility.delete(key);
    pollStates.delete(key);
    if (persist) {
      pi.appendEntry(TRACKED_PR_ENTRY, { action: "remove", pr } satisfies TrackedPrEntry);
    }
    return true;
  }

  function scheduleIdleRecheck(ctx: ExtensionContext, reason: string): void {
    if (!isEnabled()) return;
    if (recheckTimer) clearTimeout(recheckTimer);
    recheckTimer = setTimeout(() => {
      recheckTimer = undefined;
      if (
        !sessionAlive ||
        trackedPrs.size === 0 ||
        !ctx.isIdle() ||
        ctx.hasPendingMessages()
      ) {
        return;
      }
      pi.sendMessage(
        {
          customType: "ci-gate-recheck",
          content: `Recheck every session-tracked pull request now. Reason: ${reason}`,
          display: true,
        },
        { triggerTurn: true },
      );
    }, 50);
  }

  async function inspect(ctx: ExtensionContext, tracked: TrackedPr): Promise<Inspection> {
    const prResult = await pi.exec(
      ghCommand,
      [
        "pr",
        "view",
        String(tracked.number),
        "--repo",
        tracked.repo,
        "--json",
        "number,url,state,headRefName,headRefOid,baseRefName",
      ],
      { cwd: ctx.cwd, timeout: 20_000 },
    );
    if (prResult.killed || prResult.code !== 0) {
      return {
        kind: "error",
        tracked,
        reason: commandFailure("gh pr view", prResult.stderr),
      };
    }

    const pr = parseJson<PullRequest>(prResult.stdout);
    if (!pr || !Number.isInteger(pr.number) || !pr.headRefOid) {
      return { kind: "error", tracked, reason: "gh pr view returned invalid pull-request data." };
    }
    if (pr.state.toUpperCase() !== "OPEN") {
      return { kind: "inactive", tracked, pr, reason: `PR is ${pr.state}.` };
    }

    if (!tracked.checkoutPath) {
      return {
        kind: "local-checkout-error",
        tracked,
        pr,
        reason: "No source checkout was recorded for this tracked PR. Re-add it with ci_gate_track_pr from its checkout.",
      };
    }
    const remoteResult = await pi.exec(
      gitCommand,
      ["-C", tracked.checkoutPath, "remote", "get-url", "origin"],
      { timeout: 10_000 },
    );
    if (remoteResult.code !== 0 || remoteResult.killed) {
      return {
        kind: "local-checkout-error",
        tracked,
        pr,
        reason: commandFailure("git remote get-url origin", remoteResult.stderr),
      };
    }
    const checkoutRepo = repoFromGitRemote(remoteResult.stdout);
    if (checkoutRepo?.toLowerCase() !== tracked.repo.toLowerCase()) {
      return {
        kind: "local-checkout-error",
        tracked,
        pr,
        reason: `Recorded checkout ${tracked.checkoutPath} is not for ${tracked.repo}.`,
      };
    }
    const localHeadResult = await pi.exec(
      gitCommand,
      [
        "-C",
        tracked.checkoutPath,
        "rev-parse",
        "--verify",
        `refs/heads/${pr.headRefName}`,
      ],
      { timeout: 10_000 },
    );
    if (localHeadResult.code !== 0 || localHeadResult.killed || !localHeadResult.stdout.trim()) {
      return {
        kind: "local-checkout-error",
        tracked,
        pr,
        reason: commandFailure(
          `git rev-parse refs/heads/${pr.headRefName}`,
          localHeadResult.stderr,
        ),
      };
    }
    const localHead = localHeadResult.stdout.trim();
    if (localHead !== pr.headRefOid) {
      return {
        kind: "local-head-mismatch",
        tracked,
        pr,
        localHead,
        reason: `Local branch ${pr.headRefName} is at ${localHead}, but PR head is ${pr.headRefOid}. Push or synchronize it before evaluating CI.`,
      };
    }

    const checksResult = await pi.exec(
      ghCommand,
      [
        "pr",
        "checks",
        String(tracked.number),
        "--repo",
        tracked.repo,
        "--required",
        "--json",
        "name,state,bucket,link,description",
      ],
      { cwd: ctx.cwd, timeout: 30_000 },
    );
    if (checksResult.killed || ![0, 1, 8].includes(checksResult.code)) {
      return {
        kind: "error",
        tracked,
        pr,
        reason: commandFailure("gh pr checks --required", checksResult.stderr),
      };
    }
    const checks = parseJson<RequiredCheck[]>(checksResult.stdout);
    if (!Array.isArray(checks)) {
      return {
        kind: "error",
        tracked,
        pr,
        reason: `gh pr checks --required returned invalid data: ${checksResult.stderr.trim() || "no error output"}`,
      };
    }
    return { kind: "active", tracked, pr, classification: classifyChecks(checks) };
  }

  function markEligible(
    inspection: Inspection,
    condition: ReleaseEligibility["condition"],
    checkNames: string[],
    fingerprint: string,
  ): void {
    if (!inspection.pr) return;
    eligibility.set(trackedPrKey(inspection.tracked), {
      repo: inspection.tracked.repo,
      prNumber: inspection.tracked.number,
      headSha: inspection.pr.headRefOid,
      condition,
      checkNames,
      blockingFingerprint: fingerprint,
    });
  }

  function continueAgent(items: ActionableInspection[]): void {
    const details = items
      .map(({ inspection, cause }) => `${inspectionSummary(inspection)}\nCause: ${cause}`)
      .join("\n\n");
    pi.sendMessage(
      {
        customType: "ci-gate-continuation",
        content: [
          `CI gate remains closed for ${items.length} tracked pull request(s).`,
          "",
          details,
          "",
          "Continue the CI loop now. Inspect authoritative logs, fix PR-caused failures, push fixes, and recheck every tracked PR.",
          "A pending or flaky check is not an external blocker while polling or retry is possible.",
          "Only use ci_gate_report_external_blocker after the gate establishes eligibility for the exact repository, PR head, and blocking check state.",
        ].join("\n"),
        display: true,
        details: items.map(({ inspection, cause }) => ({
          repo: inspection.tracked.repo,
          prNumber: inspection.tracked.number,
          cause,
        })),
      },
      { triggerTurn: true, deliverAs: "followUp" },
    );
  }

  async function holdGate(ctx: ExtensionContext): Promise<void> {
    let delayMs = pollMs;
    while (sessionAlive && !ctx.hasPendingMessages()) {
      const inspections = await Promise.all(
        [...trackedPrs.values()].map(async (tracked) => {
          try {
            return await inspect(ctx, tracked);
          } catch (error) {
            return {
              kind: "error",
              tracked,
              reason: `CI inspection crashed: ${error instanceof Error ? error.message : String(error)}`,
            } satisfies Inspection;
          }
        }),
      );
      if (!sessionAlive || ctx.hasPendingMessages()) return;

      const now = Date.now();
      const actionable: ActionableInspection[] = [];
      let waiting = 0;
      let complete = 0;

      for (const inspection of inspections) {
        const key = trackedPrKey(inspection.tracked);
        if (inspection.kind === "inactive") {
          eligibility.delete(key);
          pollStates.delete(key);
          complete++;
          continue;
        }

        if (inspection.kind === "error") {
          const fingerprint = inspectionErrorFingerprint(inspection.reason);
          const blocker = blockers.get(key);
          if (
            inspection.pr &&
            blocker &&
            blockerCovers(blocker, inspection.pr, [REQUIRED_CHECK_REPORTING], fingerprint)
          ) {
            complete++;
            continue;
          }
          markEligible(inspection, "inspection-error", [REQUIRED_CHECK_REPORTING], fingerprint);
          actionable.push({ inspection, cause: inspection.reason });
          continue;
        }

        if (
          inspection.kind === "local-checkout-error" ||
          inspection.kind === "local-head-mismatch"
        ) {
          eligibility.delete(key);
          pollStates.delete(key);
          actionable.push({ inspection, cause: inspection.reason });
          continue;
        }

        const { pr, classification } = inspection;
        if (classification.kind === "green") {
          eligibility.delete(key);
          pollStates.delete(key);
          complete++;
          continue;
        }

        const checkNames = blockingCheckNames(classification);
        const fingerprint = blockingFingerprint(classification);
        const blocker = blockers.get(key);
        if (blocker && blockerCovers(blocker, pr, checkNames, fingerprint)) {
          complete++;
          continue;
        }

        if (classification.kind === "failed") {
          pollStates.delete(key);
          markEligible(inspection, "failed", checkNames, fingerprint);
          actionable.push({
            inspection,
            cause: "One or more required CI checks failed.",
          });
          continue;
        }

        let pollState = pollStates.get(key);
        if (
          !pollState ||
          pollState.headSha !== pr.headRefOid ||
          pollState.classificationKind !== classification.kind
        ) {
          pollState = {
            headSha: pr.headRefOid,
            classificationKind: classification.kind,
            unchangedSince: now,
            discoverySince: now,
          };
          pollStates.set(key, pollState);
        }

        if (classification.kind === "unreported") {
          if (now - pollState.discoverySince >= discoveryMs) {
            markEligible(
              inspection,
              "stalled-unreported",
              [REQUIRED_CHECK_REPORTING],
              fingerprint,
            );
            actionable.push({
              inspection,
              cause:
                "No required CI check reported before the discovery deadline. Prove whether checks are misconfigured or externally blocked; do not treat an empty list as green.",
            });
          } else {
            waiting++;
          }
          continue;
        }

        if (pollState.fingerprint !== fingerprint) {
          pollState.fingerprint = fingerprint;
          pollState.unchangedSince = now;
        } else if (now - pollState.unchangedSince >= stallMs) {
          markEligible(inspection, "stalled-pending", checkNames, fingerprint);
          actionable.push({
            inspection,
            cause: "Required CI checks made no progress before the stall deadline.",
          });
          continue;
        }
        waiting++;
      }

      if (actionable.length > 0) {
        ctx.ui.setStatus(STATUS_KEY, `CI: action needed on ${actionable.length} PR(s)`);
        continueAgent(actionable);
        return;
      }
      if (waiting === 0) {
        ctx.ui.setStatus(STATUS_KEY, `CI: complete on ${complete} tracked PR(s)`);
        return;
      }

      ctx.ui.setStatus(
        STATUS_KEY,
        `CI: waiting on ${waiting} of ${trackedPrs.size} tracked PR(s)`,
      );
      await sleep(delayMs, () => sessionAlive && !ctx.hasPendingMessages());
      delayMs = Math.min(maxPollMs, delayMs * 2);
    }
  }

  pi.on("session_start", (_event, ctx) => {
    sessionAlive = true;
    monitoring = false;
    creationCalls.clear();
    trackedPrs.clear();
    blockers.clear();
    eligibility.clear();
    pollStates.clear();

    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type !== "custom") continue;
      if (entry.customType === TRACKED_PR_ENTRY && isTrackedPrEntry(entry.data)) {
        if (entry.data.action === "add") registerPr(entry.data.pr, false);
        else removePr(entry.data.pr, false);
      } else if (entry.customType === BLOCKER_ENTRY && isExternalBlocker(entry.data)) {
        const key = trackedPrKey({ repo: entry.data.repo, number: entry.data.prNumber });
        if (entry.data.active) blockers.set(key, entry.data);
        else blockers.delete(key);
      }
    }

    if (trackedPrs.size > 0) scheduleIdleRecheck(ctx, "session resumed with tracked PRs");
  });

  pi.on("tool_call", (event) => {
    if (!isEnabled() || event.toolName !== "bash") return;
    const command = typeof event.input.command === "string" ? event.input.command : "";
    if (!looksLikePrCreation(command)) return;
    creationCalls.add(event.toolCallId);
    event.input.command = wrapPrCreationCommand(command);
  });

  pi.on("tool_result", (event) => {
    if (event.toolName !== "bash" || !creationCalls.delete(event.toolCallId) || event.isError) {
      return;
    }
    const output = event.content
      .filter((part) => part.type === "text")
      .map((part) => part.text)
      .join("\n");
    const checkoutPath = creationCheckoutPath(output);
    if (!checkoutPath) return;
    const prs = parsePullRequestUrls(output.slice(0, output.lastIndexOf(CREATION_SUCCESS_MARKER)));
    const createdPr = prs.at(-1);
    if (createdPr) registerPr({ ...createdPr, checkoutPath });
  });

  pi.on("before_agent_start", (event) => {
    if (!isEnabled()) return;
    return {
      systemPrompt:
        `${event.systemPrompt}\n\nCI gate:\n` +
        "- Pull requests created during this session are tracked automatically. If a PR is created through an unusual path, call ci_gate_track_pr with its URL.\n" +
        "- Completion requires every tracked PR's required CI checks to report green or have exact linked external-blocker evidence.",
    };
  });

  pi.on("agent_end", async (event, ctx) => {
    if (!isEnabled() || !sessionAlive || monitoring || ctx.hasPendingMessages()) return;

    const stopReason = assistantStopReason(event);
    if (stopReason === "aborted" || stopReason === undefined) return;
    if (stopReason === "error") {
      if (trackedPrs.size > 0) {
        pi.sendMessage(
          {
            customType: "ci-gate-recovery",
            content:
              "The agent run failed. Allow Pi's automatic retry or compaction recovery, then continue the task and enforce the CI gate before completion.",
            display: true,
          },
          { triggerTurn: true, deliverAs: "followUp" },
        );
      }
      return;
    }

    monitoring = true;
    try {
      if (trackedPrs.size === 0) {
        ctx.ui.setStatus(STATUS_KEY, undefined);
        return;
      }
      await holdGate(ctx);
    } finally {
      monitoring = false;
    }
  });

  pi.on("session_shutdown", (_event, ctx) => {
    sessionAlive = false;
    creationCalls.clear();
    if (recheckTimer) clearTimeout(recheckTimer);
    recheckTimer = undefined;
    ctx.ui.setStatus(STATUS_KEY, undefined);
  });

  pi.registerTool({
    name: "ci_gate_track_pr",
    label: "Track PR in CI gate",
    description: "Register a pull request created during this session so the CI gate checks it.",
    promptSnippet: "Register a newly created PR when automatic tracking may have missed it",
    parameters: Type.Object({
      url: Type.String({ minLength: 8 }),
      checkoutPath: Type.Optional(Type.String({ minLength: 1 })),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const prs = parsePullRequestUrls(params.url.trim());
      if (prs.length !== 1) throw new Error("Provide one full pull-request URL.");
      const tracked = { ...prs[0], checkoutPath: params.checkoutPath ?? ctx.cwd };
      const added = registerPr(tracked);
      return {
        content: [{
          type: "text",
          text: added ? `Tracking ${tracked.url}.` : `Already tracking ${tracked.url}.`,
        }],
        details: { pr: tracked, added },
      };
    },
  });

  pi.registerTool({
    name: "ci_gate_report_external_blocker",
    label: "Report external CI blocker",
    description:
      "Release one tracked PR only after the gate reports failed or stalled CI and linked evidence proves every blocker is external and PR-unresolvable.",
    promptSnippet: "Report a linked external blocker for an eligible tracked PR",
    parameters: Type.Object({
      repo: Type.String({ minLength: 3 }),
      prNumber: Type.Integer({ minimum: 1 }),
      headSha: Type.String({ minLength: 7 }),
      category: Type.String({ minLength: 1 }),
      reason: Type.String({ minLength: 10 }),
      evidence: Type.Array(
        Type.Object({
          checkName: Type.String({ minLength: 1 }),
          url: Type.String({ minLength: 8 }),
          observation: Type.String({ minLength: 10 }),
        }),
        { minItems: 1 },
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const key = trackedPrKey({ repo: params.repo, number: params.prNumber });
      const tracked = trackedPrs.get(key);
      if (!tracked) throw new Error(`${params.repo}#${params.prNumber} is not tracked.`);

      const inspection = await inspect(ctx, tracked);
      if (
        !inspection.pr ||
        inspection.kind === "inactive" ||
        inspection.kind === "local-checkout-error" ||
        inspection.kind === "local-head-mismatch"
      ) {
        throw new Error("Cannot verify an open tracked pull request at its synchronized local head.");
      }
      if (inspection.pr.headRefOid !== params.headSha) {
        throw new Error(`Current PR head is ${inspection.pr.headRefOid}, not ${params.headSha}.`);
      }
      if (inspection.kind === "active" && inspection.classification.kind === "green") {
        throw new Error("Required CI is already green; no blocker release is needed.");
      }

      const eligible = eligibility.get(key);
      if (!eligible || eligible.headSha !== inspection.pr.headRefOid) {
        throw new Error("The CI gate has not established blocker eligibility for this PR head.");
      }
      const currentCheckNames =
        inspection.kind === "active"
          ? blockingCheckNames(inspection.classification)
          : [REQUIRED_CHECK_REPORTING];
      const currentFingerprint =
        inspection.kind === "active"
          ? blockingFingerprint(inspection.classification)
          : inspectionErrorFingerprint(inspection.reason);
      if (
        currentFingerprint !== eligible.blockingFingerprint ||
        currentCheckNames.length !== eligible.checkNames.length ||
        currentCheckNames.some((name) => !eligible.checkNames.includes(name))
      ) {
        throw new Error("The current blocking CI state changed. Let the gate reassess it.");
      }
      if (
        inspection.kind === "active" &&
        (inspection.classification.kind === "pending" ||
          inspection.classification.kind === "unreported") &&
        !eligible.condition.startsWith("stalled-")
      ) {
        throw new Error("CI is ordinarily pending; continue polling instead of releasing it.");
      }

      const reason = params.reason.trim();
      if (reason.length < 10) throw new Error("External-blocker reason is too short.");
      if (!(EXTERNAL_CATEGORIES as readonly string[]).includes(params.category)) {
        throw new Error(`Unknown external-blocker category: ${params.category}`);
      }
      const evidence = params.evidence.map((item) => ({
        checkName: item.checkName.trim(),
        url: item.url.trim(),
        observation: item.observation.trim(),
      }));
      if (
        evidence.some(
          (item) =>
            !currentCheckNames.includes(item.checkName) ||
            !validEvidenceUrl(item.url) ||
            item.observation.length < 10,
        ) ||
        currentCheckNames.some(
          (checkName) => !evidence.some((item) => item.checkName === checkName),
        )
      ) {
        throw new Error(
          `Evidence must cover every current blocker (${currentCheckNames.join(", ")}) with an HTTP(S) link and observation.`,
        );
      }

      const blocker: ExternalBlocker = {
        active: true,
        repo: tracked.repo,
        prNumber: tracked.number,
        headSha: inspection.pr.headRefOid,
        category: params.category as ExternalBlocker["category"],
        reason,
        evidence,
        blockingFingerprint: currentFingerprint,
        reportedAt: new Date().toISOString(),
      };
      blockers.set(key, blocker);
      pi.appendEntry(BLOCKER_ENTRY, blocker);
      return {
        content: [{
          type: "text",
          text: `CI gate released for ${tracked.repo}#${tracked.number} at ${inspection.pr.headRefOid}: ${reason}`,
        }],
        details: blocker,
        terminate: true,
      };
    },
  });

  pi.registerCommand("ci-gate", {
    description: "List, add, remove, or clear session-tracked pull requests",
    handler: async (args, ctx) => {
      const [action, value] = args.trim().split(/\s+/, 2);
      if (action === "add") {
        const prs = parsePullRequestUrls(value ?? "");
        if (prs.length !== 1) {
          ctx.ui.notify("Usage: /ci-gate add <PR URL>", "error");
          return;
        }
        const tracked = { ...prs[0], checkoutPath: ctx.cwd };
        ctx.ui.notify(registerPr(tracked) ? `Tracking ${tracked.url}` : "PR already tracked", "info");
        scheduleIdleRecheck(ctx, "PR manually added");
        return;
      }
      if (action === "remove") {
        const prs = parsePullRequestUrls(value ?? "");
        if (prs.length !== 1) {
          ctx.ui.notify("Usage: /ci-gate remove <PR URL>", "error");
          return;
        }
        ctx.ui.notify(removePr(prs[0]) ? `Removed ${prs[0].url}` : "PR was not tracked", "info");
        return;
      }
      if (action === "clear") {
        for (const [key, blocker] of blockers) {
          blockers.delete(key);
          pi.appendEntry(BLOCKER_ENTRY, { ...blocker, active: false });
        }
        eligibility.clear();
        ctx.ui.notify("Cleared all external-blocker releases.", "info");
        scheduleIdleRecheck(ctx, "external-blocker releases cleared");
        return;
      }

      const lines = [...trackedPrs.values()].map((pr) => `- ${pr.url}`);
      ctx.ui.notify(
        lines.length > 0 ? `Session-tracked PRs:\n${lines.join("\n")}` : "No PRs tracked in this session.",
        "info",
      );
    },
  });
}
