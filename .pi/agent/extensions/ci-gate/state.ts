export interface PullRequest {
  number: number;
  url: string;
  state: string;
  headRefName: string;
  headRefOid: string;
  baseRefName: string;
}

export interface RequiredCheck {
  name: string;
  state: string;
  bucket: string;
  link: string;
  description: string;
}

export type CheckClassification =
  | { kind: "green"; checks: RequiredCheck[] }
  | { kind: "pending"; checks: RequiredCheck[]; pending: RequiredCheck[] }
  | { kind: "failed"; checks: RequiredCheck[]; failed: RequiredCheck[] }
  | { kind: "unreported"; checks: RequiredCheck[] };

const NON_CI_REQUIRED_CHECKS = new Set([
  "code review status",
  "cursor automation: pr loop",
]);

export function isCiCheck(check: RequiredCheck): boolean {
  return !NON_CI_REQUIRED_CHECKS.has(check.name.trim().toLowerCase());
}

export function classifyChecks(requiredChecks: RequiredCheck[]): CheckClassification {
  const checks = requiredChecks.filter(isCiCheck);
  if (checks.length === 0) return { kind: "unreported", checks };

  const failed = checks.filter((check) => {
    const bucket = check.bucket.toLowerCase();
    return bucket !== "pass" && bucket !== "pending";
  });
  if (failed.length > 0) return { kind: "failed", checks, failed };

  const pending = checks.filter((check) => check.bucket.toLowerCase() === "pending");
  if (pending.length > 0) return { kind: "pending", checks, pending };

  return { kind: "green", checks };
}

export function formatChecks(checks: RequiredCheck[]): string {
  if (checks.length === 0) return "- No required CI check has reported yet.";
  return checks
    .map((check) => {
      const detail = check.description ? ` — ${check.description}` : "";
      const link = check.link ? ` (${check.link})` : "";
      return `- ${check.name}: ${check.state}/${check.bucket}${detail}${link}`;
    })
    .join("\n");
}
