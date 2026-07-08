import SwiftUI

enum ReadinessCategory: String, Codable, CaseIterable, Identifiable {
    case pushDay = "Push Day"
    case normalTrainingDay = "Normal Training Day"
    case lightTrainingDay = "Light Training Day"
    case recoveryDay = "Recovery Day"
    case bareMinimumDay = "Bare-Minimum Day"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .pushDay: return Color(red: 0.32, green: 0.92, blue: 0.70)
        case .normalTrainingDay: return Color(red: 0.35, green: 0.64, blue: 1.00)
        case .lightTrainingDay: return Color(red: 0.78, green: 0.70, blue: 1.00)
        case .recoveryDay: return Color(red: 0.97, green: 0.73, blue: 0.40)
        case .bareMinimumDay: return Color(red: 1.00, green: 0.47, blue: 0.47)
        }
    }

    var missionTitle: String {
        switch self {
        case .pushDay: return "Build momentum"
        case .normalTrainingDay: return "Train clean"
        case .lightTrainingDay: return "Keep the promise"
        case .recoveryDay: return "Recover on purpose"
        case .bareMinimumDay: return "Protect the floor"
        }
    }

    var missionBody: String {
        switch self {
        case .pushDay:
            return "You have room to challenge yourself today. Go after the main session, keep form crisp, and finish with one quiet recovery action."
        case .normalTrainingDay:
            return "Do the planned work without chasing intensity. Solid warmup, steady effort, and leave one rep in reserve."
        case .lightTrainingDay:
            return "Move, but keep the dial down. Choose technique, zone 2, mobility, or a shorter lift with no grind reps."
        case .recoveryDay:
            return "The win is restoration. Walk, breathe, hydrate, and let the body consolidate the work already done."
        case .bareMinimumDay:
            return "No heroics. Do the smallest useful version: ten minutes of movement, protein, water, and an early off-ramp tonight."
        }
    }

    var recommendedAction: String {
        switch self {
        case .pushDay:
            return "Do the full planned session and finish with a deliberate cooldown."
        case .normalTrainingDay:
            return "Train as planned, cap the intensity, and keep the reps clean."
        case .lightTrainingDay:
            return "Choose a shorter technique, mobility, or zone 2 session."
        case .recoveryDay:
            return "Make recovery the session: walk, mobility, hydration, and sleep."
        case .bareMinimumDay:
            return "Do ten easy minutes, hit protein and water, then shut it down early."
        }
    }
}
