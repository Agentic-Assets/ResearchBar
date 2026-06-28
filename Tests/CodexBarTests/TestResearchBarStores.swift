import Foundation
@testable import CodexBarCore

// Reusable in-memory test doubles for slices 08+. These are plain helpers, not @Test
// suites, so they carry no test cases of their own.

/// In-memory `CorbisCredentialStoring` double that never touches the Keychain.
actor InMemoryCorbisCredentialStore: CorbisCredentialStoring {
    private var credential: CorbisCredential?

    init(credential: CorbisCredential? = nil) {
        self.credential = credential
    }

    func loadCredential() async throws -> CorbisCredential? {
        self.credential
    }

    func saveCredential(_ credential: CorbisCredential) async throws {
        self.credential = credential
    }

    func deleteCredential() async throws {
        self.credential = nil
    }
}
