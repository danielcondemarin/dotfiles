import assert from "node:assert/strict";
import test from "node:test";
import {
  parsePullRequestUrls,
  repoFromGitRemote,
  trackedPrKey,
} from "./tracker.ts";

test("parses and deduplicates pull-request URLs", () => {
  assert.deepEqual(
    parsePullRequestUrls(
      "Created https://github.com/samsara-dev/backend/pull/123\nhttps://github.com/samsara-dev/backend/pull/123",
    ),
    [{ repo: "samsara-dev/backend", number: 123, url: "https://github.com/samsara-dev/backend/pull/123" }],
  );
});

test("parses HTTPS and SSH Git remotes", () => {
  assert.equal(repoFromGitRemote("https://github.com/samsara-dev/backend.git"), "samsara-dev/backend");
  assert.equal(repoFromGitRemote("git@github.com:samsara-dev/backend.git"), "samsara-dev/backend");
});

test("builds case-insensitive repository keys", () => {
  assert.equal(trackedPrKey({ repo: "Samsara-Dev/Backend", number: 123 }), "samsara-dev/backend#123");
});
