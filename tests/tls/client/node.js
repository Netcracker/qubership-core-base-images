const assert = require("node:assert/strict");

const expectUntrusted = process.env.EXPECT_UNTRUSTED === "1";
const request = fetch(process.env.URL, { signal: AbortSignal.timeout(5000) });

async function check() {
  if (expectUntrusted) {
    await assert.rejects(request, error => {
      return ["UNABLE_TO_VERIFY_LEAF_SIGNATURE", "UNABLE_TO_GET_ISSUER_CERT_LOCALLY",
        "SELF_SIGNED_CERT_IN_CHAIN"].includes(error.cause?.code);
    });
    return;
  }
  const response = await request;
  assert.equal(response.status, 200);
  assert.equal(await response.text(), "OK");
}

check().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
