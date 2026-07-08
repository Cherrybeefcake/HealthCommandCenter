import Foundation

final class CheckInViewModel: ObservableObject {
    @Published var energy = 7
    @Published var soreness = 4
    @Published var stress = 4
    @Published var mood = 7
    @Published var availableWorkoutMinutes = 45
    @Published var painNote = ""
}
