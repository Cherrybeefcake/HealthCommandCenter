import Foundation

protocol HealthDataProviding {
    func requestAuthorization() async throws
    func fetchTodaySnapshot() async throws -> HealthSnapshot
}

enum HealthDataError: LocalizedError {
    case unavailable
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Health data is not available on this device."
        case .authorizationDenied:
            return "Health permission was not granted."
        }
    }
}
