import Foundation
import Testing
@testable import CodexBarCore

@Suite(.serialized)
struct CorbisCredentialStoreTests {
    @Test
    func fingerprintIsDeterministicAndHidesToken() {
        let token = "secret-bearer-token-abc123"
        let first = CorbisAccountIdentity.fingerprint(forToken: token)
        let second = CorbisAccountIdentity.fingerprint(forToken: token)
        #expect(first == second)
        #expect(!first.contains(token))
        #expect(first.count == 64)
    }

    @Test
    func fingerprintDiffersPerToken() {
        let one = CorbisAccountIdentity.fingerprint(forToken: "token-one")
        let two = CorbisAccountIdentity.fingerprint(forToken: "token-two")
        #expect(one != two)
    }

    @Test
    func cacheKeyComponentPrefersAccountIDElseAnonFingerprint() {
        let linked = CorbisAccountIdentity.make(accountID: "acct-42", token: "t")
        #expect(linked.cacheKeyComponent == "acct-42")

        let anon = CorbisAccountIdentity.make(accountID: nil, token: "t")
        #expect(anon.cacheKeyComponent == "anon-\(anon.tokenFingerprint)")
    }

    @Test
    func credentialDescriptionsNeverContainTheToken() {
        let token = "super-secret-xyz-987"
        let credential = CorbisCredential(
            token: token,
            accountID: "acct-1",
            displayEmail: "researcher@uni.edu",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastValidatedAt: nil)
        #expect(!credential.description.contains(token))
        #expect(!credential.debugDescription.contains(token))
        #expect(credential.description.contains("<redacted>"))
        #expect("\(credential)".contains("<redacted>"))
    }

    @Test
    func saveThenLoadReturnsEqualCredential() async throws {
        try await Self.withStore { store in
            let credential = Self.sampleCredential()
            try await store.saveCredential(credential)
            let loaded = try await store.loadCredential()
            #expect(loaded == credential)
        }
    }

    @Test
    func loadOnEmptyStoreReturnsNil() async throws {
        try await Self.withStore { store in
            let loaded = try await store.loadCredential()
            #expect(loaded == nil)
        }
    }

    @Test
    func deleteThenLoadReturnsNil() async throws {
        try await Self.withStore { store in
            try await store.saveCredential(Self.sampleCredential())
            try await store.deleteCredential()
            let loaded = try await store.loadCredential()
            #expect(loaded == nil)
        }
    }

    // MARK: - Helpers

    private static func sampleCredential() -> CorbisCredential {
        CorbisCredential(
            token: "tok-123-abc",
            accountID: "acct-9",
            displayEmail: "rhea@tulsa.edu",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastValidatedAt: Date(timeIntervalSince1970: 1_700_000_600))
    }

    /// Run `body` against a Keychain store backed by a unique, isolated test store so no
    /// real Keychain access or UI prompt can occur.
    private static func withStore(
        _ body: (KeychainCorbisCredentialStore) async throws -> Void) async throws
    {
        try await KeychainCacheStore.withServiceOverrideForTesting("corbis-test-\(UUID().uuidString)") {
            KeychainCacheStore.setTestStoreForTesting(true)
            defer { KeychainCacheStore.setTestStoreForTesting(false) }
            try await body(KeychainCorbisCredentialStore())
        }
    }
}
