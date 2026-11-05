import assert from "node:assert/strict";
import test from "node:test";
import { classifyChecks, formatChecks, type RequiredCheck } from "./state.ts";

function check(name: string, bucket: string, state = bucket.toUpperCase()): RequiredCheck {
  return { name, bucket, state, link: `https://ci.example/${name}`, description: "" };
}

test("reports unreported when no required CI checks exist", () => {
  assert.equal(classifyChecks([]).kind, "unreported");
});

test("ignores required human review gates", () => {
  assert.equal(classifyChecks([check("Code Review Status", "pending")]).kind, "unreported");
});

test("stays pending while any required CI check is pending", () => {
  assert.equal(
    classifyChecks([check("buildkite/backend-pr", "pass"), check("tests", "pending")]).kind,
    "pending",
  );
});

test("fails on failed, cancelled, skipped, or unknown required checks", () => {
  for (const bucket of ["fail", "cancel", "skipping", "unknown"]) {
    assert.equal(classifyChecks([check("tests", bucket)]).kind, "failed");
  }
});

test("goes green only when every required CI check passes", () => {
  assert.equal(
    classifyChecks([check("buildkite/backend-pr", "pass"), check("codecov/patch", "pass")]).kind,
    "green",
  );
});

test("formats check evidence", () => {
  const output = formatChecks([
    {
      ...check("tests", "fail", "FAILURE"),
      description: "unit test failed",
      link: "https://ci.example/failure",
    },
  ]);
  assert.match(output, /tests: FAILURE\/fail/);
  assert.match(output, /unit test failed/);
  assert.match(output, /https:\/\/ci\.example\/failure/);
});
