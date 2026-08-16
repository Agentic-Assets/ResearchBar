import Foundation
#if os(macOS)
import Security
#endif
import Testing
@testable import CodexBarCore

@Suite(.serialized)
struct CorbisCredentialStoreTests {
    @Test
    func `fingerprint is deterministic and hides token`() {
        let token = "secret-bearer-token-abc123"
        let first = CorbisAccountIdentity.fingerprint(forToken: token)
        let second = CorbisAccountIdentity.fingerprint(forToken: token)
        #expect(first == second)
        #expect(!first.contains(token))
        #expect(first.count == 64)
    }

    @Test
    func `fingerprint differs per token`() {
        let one = CorbisAccountIdentity.fingerprint(forToken: "token-one")
        let two = CorbisAccountIdentity.fingerprint(forToken: "token-two")
        #expect(one != two)
    }

    @Test
    func `cache key component prefers account ID else anon fingerprint`() {
        let linked = CorbisAccountIdentity.make(accountID: "acct-42", token: "t")
        #expect(linked.cacheKeyComponent == "acct-42")

        let anon = CorbisAccountIdentity.make(accountID: nil, token: "t")
        #expect(anon.cacheKeyComponent == "anon-\(anon.tokenFingerprint)")
    }

    @Test
    func `credential descriptions never contain the token`() {
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
    func `save then load returns equal credential`() async throws {
        try await Self.withStore { store, _ in
            let credential = Self.sampleCredential()
            try await store.saveCredential(credential)
            let loaded = try await store.loadCredential()
            #expect(loaded == credential)
        }
    }

    @Test
    func `load on empty store returns nil`() async throws {
        try await Self.withStore { store, _ in
            let loaded = try await store.loadCredential()
            #expect(loaded == nil)
        }
    }

    @Test
    func `delete then load returns nil`() async throws {
        try await Self.withStore { store, _ in
            try await store.saveCredential(Self.sampleCredential())
            try await store.deleteCredential()
            let loaded = try await store.loadCredential()
            #expect(loaded == nil)
        }
    }

    @Test
    func `readable legacy credential remains available until replacement`() async throws {
        try await Self.withStore { store, _ in
            let legacy = Self.sampleCredential(token: "corbis_mcp_legacy")
            KeychainCacheStore.store(key: KeychainCorbisCredentialStore.legacyKey, entry: legacy)

            let loaded = try await store.loadCredential()
            #expect(loaded == legacy)
        }
    }

    @Test
    func `new credential writes v2 without modifying legacy record`() async throws {
        try await Self.withStore { store, keychain in
            let legacy = Self.sampleCredential(token: "corbis_mcp_legacy")
            let replacement = Self.sampleCredential(token: "corbis_mcp_replacement")
            KeychainCacheStore.store(key: KeychainCorbisCredentialStore.legacyKey, entry: legacy)

            try await store.saveCredential(replacement)

            let loaded = try await store.loadCredential()
            #expect(loaded == replacement)
            let reopenedStore = KeychainCorbisCredentialStore(keychain: keychain)
            let reopenedCredential = try await reopenedStore.loadCredential()
            #expect(reopenedCredential == replacement)
            let savedData = try #require(keychain.data)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let savedCredential = try decoder.decode(CorbisCredential.self, from: savedData)
            #expect(savedCredential == replacement)
            let preservedLegacy: CorbisCredential? = switch KeychainCacheStore.load(
                key: KeychainCorbisCredentialStore.legacyKey,
                as: CorbisCredential.self)
            {
            case let .found(credential): credential
            case .missing, .temporarilyUnavailable, .invalid: nil
            }
            #expect(preservedLegacy == legacy)
        }
    }

    #if os(macOS)
    @Test
    func `v2 file keychain queries omit data protection only attributes`() {
        let service = "com.example.researchbar"
        let account = "corbis-credential"
        let data = Data("credential".utf8)

        let loadQuery = CorbisCredentialKeychainQuery.load(service: service, account: account)
        let updateQuery = CorbisCredentialKeychainQuery.item(service: service, account: account)
        let addQuery = CorbisCredentialKeychainQuery.add(data: data, service: service, account: account)
        let deleteQuery = CorbisCredentialKeychainQuery.item(service: service, account: account)

        for query in [loadQuery, updateQuery, addQuery, deleteQuery] {
            #expect(query[kSecAttrService as String] as? String == service)
            #expect(query[kSecAttrAccount as String] as? String == account)
            #expect(query[kSecUseDataProtectionKeychain as String] == nil)
            #expect(query[kSecAttrAccessGroup as String] == nil)
            #expect(query[kSecAttrAccessible as String] == nil)
        }
        #expect(addQuery[kSecValueData as String] as? Data == data)
        let updateAttributes = CorbisCredentialKeychainQuery.updateAttributes(data: data)
        #expect(updateAttributes.count == 1)
        #expect(updateAttributes[kSecValueData as String] as? Data == data)
    }

    @Test
    func `failed keychain operation maps to a redacted store failure`() async {
        let keychain = InMemoryCorbisCredentialKeychain(
            saveResult: .failed(operation: .add, status: errSecParam))
        let store = KeychainCorbisCredentialStore(keychain: keychain)

        await #expect(throws: CorbisCredentialStoreError.writeFailed) {
            try await store.saveCredential(Self.sampleCredential(token: "corbis_mcp_do-not-log"))
        }
    }
    #endif

    // MARK: - Helpers

    private static func sampleCredential(token: String = "tok-123-abc") -> CorbisCredential {
        CorbisCredential(
            token: token,
            accountID: "acct-9",
            displayEmail: "rhea@tulsa.edu",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastValidatedAt: Date(timeIntervalSince1970: 1_700_000_600))
    }

    /// Run `body` against a Keychain store backed by a unique, isolated test store so no
    /// real Keychain access or UI prompt can occur.
    private static func withStore(
        _ body: (KeychainCorbisCredentialStore, InMemoryCorbisCredentialKeychain) async throws -> Void) async throws
    {
        try await KeychainCacheStore.withServiceOverrideForTesting("corbis-test-\(UUID().uuidString)") {
            KeychainCacheStore.setTestStoreForTesting(true)
            defer { KeychainCacheStore.setTestStoreForTesting(false) }
            let keychain = InMemoryCorbisCredentialKeychain()
            try await body(KeychainCorbisCredentialStore(keychain: keychain), keychain)
        }
    }
}

private final class InMemoryCorbisCredentialKeychain: CorbisCredentialKeychainOperating, @unchecked Sendable {
    private let lock = NSLock()
    private var storedData: Data?
    private let saveResult: CorbisCredentialKeychainSaveResult

    init(saveResult: CorbisCredentialKeychainSaveResult = .saved) {
        self.saveResult = saveResult
    }

    var data: Data? {
        self.lock.withLock { self.storedData }
    }

    func load(service _: String, account _: String) -> CorbisCredentialKeychainLoadResult {
        self.lock.withLock {
            guard let storedData else { return .missing }
            return .found(storedData)
        }
    }

    func save(data: Data, service _: String, account _: String) -> CorbisCredentialKeychainSaveResult {
        self.lock.withLock {
            guard self.saveResult == .saved else { return self.saveResult }
            self.storedData = data
            return .saved
        }
    }

    func delete(service _: String, account _: String) -> CorbisCredentialKeychainDeleteResult {
        self.lock.withLock {
            guard self.storedData != nil else { return .missing }
            self.storedData = nil
            return .removed
        }
    }
}
