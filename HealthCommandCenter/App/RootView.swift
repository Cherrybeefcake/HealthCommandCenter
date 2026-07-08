import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appModel: AppViewModel

    var body: some View {
        Group {
            switch appModel.route {
            case .greeting:
                GreetingView()
            case .checkIn:
                CheckInView(viewModel: CheckInViewModel())
            case .result:
                ReadinessResultView()
            case .home:
                HomeDashboardView()
            }
        }
        .task {
            await appModel.bootstrap()
        }
    }
}
