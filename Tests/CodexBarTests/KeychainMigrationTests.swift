import CodexBarCore
import Testing
@testable import CodexBar

struct KeychainMigrationTests {
    @Test
    func `service rename targets the legacy CapitalCase service and a distinct flag`() {
        // The legacy service attribute is CapitalCase; using the lowercase
        // legacyBundleIdentifierBase here would silently match nothing.
        #expect(AppIdentity.legacyKeychainSecretsService == "com.steipete.CodexBar")
        #expect(AppIdentity.legacyKeychainSecretsService != AppIdentity.keychainSecretsService)
        // A separate flag from the accessibility migration, so a build that already ran the
        // accessibility upgrade still performs the rename exactly once.
        #expect(KeychainMigration.serviceRenameKey != "KeychainMigrationV1Completed")
    }

    @Test
    func `migration list covers known keychain items`() {
        let items = Set(KeychainMigration.itemsToMigrate.map(\.label))
        let expected: Set = [
            "com.corbis.researchbar:codex-cookie",
            "com.corbis.researchbar:claude-cookie",
            "com.corbis.researchbar:cursor-cookie",
            "com.corbis.researchbar:factory-cookie",
            "com.corbis.researchbar:minimax-cookie",
            "com.corbis.researchbar:minimax-api-token",
            "com.corbis.researchbar:augment-cookie",
            "com.corbis.researchbar:copilot-api-token",
            "com.corbis.researchbar:zai-api-token",
            "com.corbis.researchbar:synthetic-api-key",
        ]

        let missing = expected.subtracting(items)
        #expect(missing.isEmpty, "Missing migration entries: \(missing.sorted())")
    }
}
