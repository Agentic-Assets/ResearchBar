import Foundation

/// The result of validating and persisting a candidate Corbis credential.
///
/// Each failure is deliberately category-only: neither the token nor a raw server or
/// Keychain error is carried into the settings surface.
public enum CorbisCredentialConnectionResult: Equatable, Sendable {
    case connected(CorbisCredential)
    case invalidCredential
    case validationUnavailable
    case storageUnavailable
}

/// Validates a replacement credential before changing local state.
///
/// This keeps a working stored credential and its cache intact if a pasted replacement is
/// rejected or the service is temporarily unavailable.
public struct CorbisCredentialConnector: Sendable {
    private let credentialStore: any CorbisCredentialStoring
    private let cache: any ResearchPulseCaching
    private let client: CorbisMCPClient

    public init(
        credentialStore: any CorbisCredentialStoring,
        cache: any ResearchPulseCaching,
        client: CorbisMCPClient)
    {
        self.credentialStore = credentialStore
        self.cache = cache
        self.client = client
    }

    public func connect(token: String) async -> CorbisCredentialConnectionResult {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await self.client.validateCredential(token: normalizedToken)
        } catch CorbisMCPError.invalidCredential {
            return .invalidCredential
        } catch {
            return .validationUnavailable
        }

        let credential = CorbisCredential(
            token: normalizedToken,
            accountID: nil,
            displayEmail: nil,
            createdAt: Date(),
            lastValidatedAt: Date())
        do {
            try await self.credentialStore.saveCredential(credential)
        } catch {
            return .storageUnavailable
        }
        await self.cache.clearAll()
        return .connected(credential)
    }
}
