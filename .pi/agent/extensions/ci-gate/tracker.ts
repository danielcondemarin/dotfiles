export interface TrackedPr {
  repo: string;
  number: number;
  url: string;
  checkoutPath?: string;
}

const PR_URL_PATTERN = /https?:\/\/[^/\s]+\/([^/\s]+)\/([^/\s]+)\/pull\/(\d+)/g;

export function trackedPrKey(pr: Pick<TrackedPr, "repo" | "number">): string {
  return `${pr.repo.toLowerCase()}#${pr.number}`;
}

export function parsePullRequestUrls(text: string): TrackedPr[] {
  const prs = new Map<string, TrackedPr>();
  for (const match of text.matchAll(PR_URL_PATTERN)) {
    const owner = match[1];
    const repository = match[2];
    const number = Number.parseInt(match[3], 10);
    if (!owner || !repository || !Number.isInteger(number) || number < 1) continue;
    const pr = {
      repo: `${owner}/${repository}`,
      number,
      url: match[0],
    };
    prs.set(trackedPrKey(pr), pr);
  }
  return [...prs.values()];
}

export function repoFromGitRemote(remote: string): string | undefined {
  const trimmed = remote.trim().replace(/\.git$/, "");
  const ssh = trimmed.match(/^[^@\s]+@[^:\s]+:([^/\s]+)\/([^/\s]+)$/);
  if (ssh) return `${ssh[1]}/${ssh[2]}`;

  try {
    const url = new URL(trimmed);
    const parts = url.pathname.split("/").filter(Boolean);
    if (parts.length >= 2) return `${parts[0]}/${parts[1]}`;
  } catch {
    return undefined;
  }
  return undefined;
}
