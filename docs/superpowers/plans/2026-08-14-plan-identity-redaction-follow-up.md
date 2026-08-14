# ResearchBar Plan Identity Redaction Follow-up Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the final review’s plan-label privacy false negative so common hyphen- and underscore-delimited account identifiers are rejected before live or cached ResearchBar presentation.

**Architecture:** Keep plan labels open-ended and descriptive by extending the existing pattern-based `ResearchPulseRedactor.containsPrivateIdentityEvidence(_:)` boundary rather than introducing a fixed entitlement allow-list. The existing live MCP client and cached card projection already fail closed when this boundary reports a violation, so tests must prove the newly recognized forms travel through both paths and a descriptive plan remains permitted.

**Tech Stack:** Swift 6, Swift Testing, SwiftPM, existing Makefile verification.

## Global Constraints

- Do not expose raw tokens, account IDs, emails, private identity evidence, backend/source plumbing, or invented entitlement data in any rendered ResearchBar surface.
- Keep plan names open-ended; do not add a frozen allowed-plan list.
- Recognize hyphen, underscore, and whitespace-delimited `account`, `acct`, or `user` identifier forms when the value has identifier-like structure, including `user-id-48291` and `acct-48291`.
- Preserve a descriptive non-identifier plan label as renderable.
- Do not change Corbis transport, cache keying, provider behavior, package/target identities, or CLI help.
- Do not access live providers, browser cookies, or macOS Keychain; every test command must set `CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1`.
- Run focused redaction/client/card tests, `make check`, and `make test` at the committed exact head.

---

### Task 1: Reject delimited plan account identifiers

**Files:**
- Modify: `Sources/CodexBarCore/ResearchBar/ResearchPulseRedactor.swift:145-168`
- Modify: `Tests/CodexBarTests/ResearchPulseRedactorTests.swift:143-165`
- Modify: `Tests/CodexBarTests/CorbisMCPClientTests.swift:250-264`
- Modify: `Tests/CodexBarTests/ResearchPulseCardModelTests.swift:87-100`

**Interfaces:**
- Consumes: `ResearchPulseRedactor.containsPrivateIdentityEvidence(_:) -> Bool` before `ResearchPulseRedactor.isClean(_:)` is used by `CorbisMCPClient.fetchResearchPulse` and `ResearchPulseCardModel.make(from:)`.
- Produces: fail-closed live client errors and cached safe-error cards for delimited account identifiers, while ordinary descriptive plan labels continue to project normally.

- [ ] **Step 1: Add redaction regressions before changing the matcher**

Extend the existing plan-identity test coverage with the exact examples:

```swift
#expect(ResearchPulseRedactor.containsPrivateIdentityEvidence("Academic user-id-48291"))
#expect(ResearchPulseRedactor.containsPrivateIdentityEvidence("Academic acct-48291"))
#expect(ResearchPulseRedactor.containsPrivateIdentityEvidence("Academic account_id_48291"))
#expect(!ResearchPulseRedactor.containsPrivateIdentityEvidence("Academic Research Plan"))
```

Add a live decoded client test whose plan is `Academic user-id-48291`, expecting `CorbisMCPError.redactionFailed`. Change the cached card privacy test to use `Academic acct-48291`, expecting `.safeError` with no plan or credit.

- [ ] **Step 2: Run focused tests to capture the false negative**

Run:

```bash
CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --no-parallel --filter 'ResearchPulseRedactorTests|CorbisMCPClientTests|ResearchPulseCardModelTests'
```

Expected: FAIL for the hyphen-delimited examples, live client, and cached card because the current matcher only accepts marker separators or underscore prefixes.

- [ ] **Step 3: Broaden only the typed plan-identity pattern**

Add a `delimitedIdentifier` regular expression to `containsPrivateIdentityEvidence(_:)` that recognizes an `acct`, `account`, or `user` marker followed by whitespace, `_`, or `-`, with optional `id`, `identifier`, or `uuid`, then an identifier-like value containing a digit. Include it in the existing pattern scan.

The pattern must accept the exact failing examples and keep `Academic Research Plan` false. Leave email, marker, underscore-prefix, UUID, credential, and all other redaction behavior intact.

- [ ] **Step 4: Run focused tests to verify both presentation boundaries**

Run:

```bash
CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --no-parallel --filter 'ResearchPulseRedactorTests|CorbisMCPClientTests|ResearchPulseCardModelTests'
```

Expected: PASS; the client throws before returning a live pulse, the cached card is fail-closed, and the descriptive control remains allowed.

- [ ] **Step 5: Commit the redaction correction**

```bash
git add Sources/CodexBarCore/ResearchBar/ResearchPulseRedactor.swift \
  Tests/CodexBarTests/ResearchPulseRedactorTests.swift \
  Tests/CodexBarTests/CorbisMCPClientTests.swift \
  Tests/CodexBarTests/ResearchPulseCardModelTests.swift
git commit -m "fix: reject delimited Corbis account identifiers"
```

## Verification

- [ ] `CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --no-parallel --filter 'ResearchPulseRedactorTests|CorbisMCPClientTests|ResearchPulseCardModelTests'`
- [ ] `make check`
- [ ] `make test`
