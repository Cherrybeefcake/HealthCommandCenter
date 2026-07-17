import Foundation
import Security

enum OuraCredentialState: String, Codable, Hashable {
    case notConfigured = "Not Configured"
    case missingToken = "Missing Token"
    case tokenStored = "Token Stored"
    case expired = "Expired"
    case revoked = "Revoked"
}

struct OuraOAuthTokens: Codable, Hashable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?
    let tokenType: String
}

struct OuraSyncResult {
    let credentialState: OuraCredentialState
    let dailySummary: OuraDailySummary?
    let message: String
    let syncedAt: Date
}

struct OuraAPIReadinessPayload: Codable, Hashable {
    var readinessScore: Int?
    var sleepScore: Int?
    var sleepDurationHours: Double?
    var restingHeartRate: Double?
    var hrv: Double?
    var bodyTemperatureTrend: String?
    var hrvBalance: String?

    var dailySummary: OuraDailySummary {
        OuraDailySummary(
            readinessScore: readinessScore,
            sleepScore: sleepScore,
            sleepDurationHours: sleepDurationHours,
            restingHeartRate: restingHeartRate,
            hrv: hrv,
            bodyTemperatureTrend: bodyTemperatureTrend,
            hrvBalance: hrvBalance
        )
    }
}

protocol OuraOAuthCoordinating {
    func authorizationURL() throws -> URL
    func exchangeCallback(url: URL) async throws -> OuraOAuthTokens
    func refresh(tokens: OuraOAuthTokens) async throws -> OuraOAuthTokens
}

protocol OuraAPIProviding {
    func fetchLatestReadiness(tokens: OuraOAuthTokens) async throws -> OuraAPIReadinessPayload
}

protocol OuraTokenStoring {
    func credentialState() -> OuraCredentialState
    func loadTokens() throws -> OuraOAuthTokens?
    func saveTokens(_ tokens: OuraOAuthTokens) throws
    func deleteTokens() throws
}

final class KeychainOuraTokenStore: OuraTokenStoring {
    private let service = "com.brian.healthcommandcenter.oura"
    private let account = "oauth-tokens"

    func credentialState() -> OuraCredentialState {
        do {
            guard let tokens = try loadTokens() else { return .missingToken }
            if let expiresAt = tokens.expiresAt, expiresAt <= Date() {
                return .expired
            }
            return .tokenStored
        } catch {
            return .missingToken
        }
    }

    func loadTokens() throws -> OuraOAuthTokens? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw KeychainError.unhandled(status)
        }
        return try JSONDecoder().decode(OuraOAuthTokens.self, from: data)
    }

    func saveTokens(_ tokens: OuraOAuthTokens) throws {
        let data = try JSONEncoder().encode(tokens)
        var query = baseQuery()
        let attributes: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            query[kSecValueData as String] = data
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandled(addStatus)
            }
            return
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
    }

    func deleteTokens() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
    }

    enum KeychainError: Error {
        case unhandled(OSStatus)
    }
}

struct PlaceholderOuraOAuthCoordinator: OuraOAuthCoordinating {
    func authorizationURL() throws -> URL {
        throw OuraIntegrationError.notConfigured
    }

    func exchangeCallback(url: URL) async throws -> OuraOAuthTokens {
        throw OuraIntegrationError.notConfigured
    }

    func refresh(tokens: OuraOAuthTokens) async throws -> OuraOAuthTokens {
        throw OuraIntegrationError.notConfigured
    }
}

struct PlaceholderOuraAPIProvider: OuraAPIProviding {
    func fetchLatestReadiness(tokens: OuraOAuthTokens) async throws -> OuraAPIReadinessPayload {
        throw OuraIntegrationError.notConfigured
    }
}

enum OuraIntegrationError: Error {
    case notConfigured
}
