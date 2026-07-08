import SwiftUI

@main
struct HealthCommandCenterApp: App {
    @StateObject private var appModel = AppViewModel(
        storage: LocalStorageService(),
        healthService: HealthKitHealthDataService(),
        ouraService: MockOuraService(),
        classifier: ReadinessClassifier()
    )

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
                .preferredColorScheme(.dark)
        }
    }
}
