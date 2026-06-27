import Testing
@testable import CodexBar

struct KeychainMigrationTests {
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
