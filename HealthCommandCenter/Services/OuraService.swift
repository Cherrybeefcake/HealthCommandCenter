import Foundation

protocol OuraService {
    var isConnected: Bool { get }
    func fetchDailySummary() async throws -> OuraDailySummary?
}

final class MockOuraService: OuraService {
    var isConnected: Bool { false }

    func fetchDailySummary() async throws -> OuraDailySummary? {
        nil
    }
}
