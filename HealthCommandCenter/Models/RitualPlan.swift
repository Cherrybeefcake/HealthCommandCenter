import Foundation

enum RitualItemKind: String, Codable, CaseIterable {
    case movement = "Movement / Steps"
    case mobility = "Stretching & Mobility"
    case meditation = "Meditation / Mental Reset"
    case cronometer = "Cronometer / Nutrition Tracking"
    case protein = "Protein Target"
    case water = "Water Target"
    case caffeine = "Caffeine Cutoff"
    case sleep = "Sleep Routine"
    case dailyWin = "Daily Win"
}

struct RitualItem: Codable, Identifiable, Hashable {
    let id: String
    let kind: RitualItemKind
    let title: String
    let description: String
    let detailTitle: String
    let details: [String]
    let recommendation: String
    let isRequired: Bool
}

struct DailyRitualLog: Codable, Identifiable, Hashable {
    let dateKey: String
    var completedItemIDs: Set<String>
    var dailyWinText: String
    var updatedAt: Date

    var id: String { dateKey }

    init(dateKey: String, completedItemIDs: Set<String> = [], dailyWinText: String = "", updatedAt: Date = Date()) {
        self.dateKey = dateKey
        self.completedItemIDs = completedItemIDs
        self.dailyWinText = dailyWinText
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case dateKey
        case completedItemIDs
        case dailyWinText
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dateKey = try container.decode(String.self, forKey: .dateKey)
        completedItemIDs = try container.decodeIfPresent(Set<String>.self, forKey: .completedItemIDs) ?? []
        dailyWinText = try container.decodeIfPresent(String.self, forKey: .dailyWinText) ?? ""
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

enum RitualDayStatus: String, Hashable {
    case complete = "Complete"
    case solid = "Solid"
    case partial = "Partial"
    case bareMinimum = "Bare Minimum"
    case missed = "Missed"
}

struct RitualDaySummary: Identifiable, Hashable {
    let log: DailyRitualLog
    let date: Date
    let category: ReadinessCategory?
    let items: [RitualItem]

    var id: String { log.dateKey }
    var dateKey: String { log.dateKey }

    var completedItems: [RitualItem] {
        items.filter { isComplete($0) }
    }

    var incompleteItems: [RitualItem] {
        items.filter { !isComplete($0) }
    }

    var completedCount: Int {
        completedItems.count
    }

    var totalCount: Int {
        max(items.count, 1)
    }

    var completionPercent: Int {
        Int((Double(completedCount) / Double(totalCount) * 100).rounded())
    }

    var status: RitualDayStatus {
        if category == .bareMinimumDay && completedCount > 0 {
            return .bareMinimum
        }
        if completedCount == 0 {
            return .missed
        }
        if completionPercent >= 100 {
            return .complete
        }
        if completionPercent >= 70 {
            return .solid
        }
        return .partial
    }

    var coachingLine: String {
        switch status {
        case .complete:
            return "Clean day. The system got the support it needed."
        case .solid:
            return "Strong enough to matter. Keep repeating this before making it bigger."
        case .partial:
            return "Useful signals landed. Next time, start with the smallest required item."
        case .bareMinimum:
            return "Good floor protection. Bare-minimum days count when they keep the chain alive."
        case .missed:
            return "No drama. Use the next day to restart with one small anchor."
        }
    }

    var usedBareMinimumRitual: Bool {
        category == .bareMinimumDay || items.count <= RitualLibrary.items(for: .bareMinimumDay).count
    }

    var dailyWinText: String {
        log.dailyWinText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isComplete(_ item: RitualItem) -> Bool {
        if item.kind == .dailyWin, !dailyWinText.isEmpty {
            return true
        }
        return log.completedItemIDs.contains(item.id)
    }
}

struct RitualLibrary {
    static func dateKey(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func items(for category: ReadinessCategory) -> [RitualItem] {
        switch category {
        case .pushDay, .normalTrainingDay:
            return normalItems(category: category)
        case .lightTrainingDay:
            return lightTrainingItems
        case .recoveryDay:
            return recoveryItems
        case .bareMinimumDay:
            return bareMinimumItems
        }
    }

    static func coachingLine(for category: ReadinessCategory) -> String {
        switch category {
        case .pushDay:
            return "Use the day, Brian. Keep the basics tight so the extra work has somewhere to land."
        case .normalTrainingDay:
            return "Do the ordinary things well today. That is the system working."
        case .lightTrainingDay:
            return "Reduce friction. Mobility, hydration, and stress control are the main levers."
        case .recoveryDay:
            return "Protect the recovery window. Walk, breathe, eat, and shut the day down cleanly."
        case .bareMinimumDay:
            return "Shrink the ritual until it is impossible to miss. Keep the floor intact."
        }
    }
}

private extension RitualLibrary {
    static func normalItems(category: ReadinessCategory) -> [RitualItem] {
        [
            item(.movement, "Movement / Steps", "Get enough easy movement to keep the day from getting stale.", "Today's target", ["Aim for a practical step floor.", "Add a 10-minute walk after a meal if the day gets crowded."], category == .pushDay ? "Let steps support recovery. Do not turn every walk into training." : "Keep steps steady and unremarkable.", true),
            item(.mobility, "Stretching & Mobility", "A short daily reset to keep joints ready for training.", "Choose one", mobilityOptions, "Five minutes is enough today. Prioritize hips, shoulders, and breathing.", true),
            item(.meditation, "Meditation / Mental Reset", "Downshift the nervous system before stress writes the plan for you.", "Choose one", meditationOptions, "Use the 2-minute reset if the day is moving fast.", true),
            item(.cronometer, "Cronometer / Nutrition Tracking", "Open Cronometer and log enough to keep nutrition honest.", "Simple rule", ["Log meals before the day gets blurry.", "Accuracy beats perfection."], "Track the anchors: protein, calories, and any misses.", true),
            item(.protein, "Protein Target", "Hit the protein floor so training has raw material.", "Simple rule", ["Build each meal around a protein source.", "Use a shake if the day is slipping."], "Make this one boring and dependable.", true),
            item(.water, "Water Target", "Hydration keeps energy, hunger, and training quality steadier.", "Simple rule", ["Start with a full bottle early.", "Add electrolytes if sweating or training."], "Front-load water before afternoon drift.", true),
            item(.caffeine, "Caffeine Cutoff", "Protect tonight's sleep before tonight arrives.", "Cutoff", ["Set the cutoff before the second coffee.", "Choose decaf or water after the cutoff."], "Caffeine after the cutoff has to earn its cost.", true),
            item(.sleep, "Sleep Routine", "Give the day a clean landing.", "Shutdown cues", ["Dim screens.", "Set tomorrow's first move.", "Get into bed on purpose."], "Tonight's sleep is tomorrow's readiness.", true),
            item(.dailyWin, "Daily Win", "Name one thing that made the day count.", "Prompt", ["What did you do today that future Brian benefits from?"], "Do not overthink it. One honest win.", false)
        ]
    }

    static let lightTrainingItems: [RitualItem] = [
        item(.movement, "Movement / Steps", "Use easy movement to stay loose without adding fatigue.", "Today's target", ["Walk in small pieces.", "Stop well before it feels like conditioning."], "Easy walking is the win. Keep it restorative.", true),
        item(.mobility, "Stretching & Mobility", "Mobility is the training support today.", "Choose one", mobilityOptions, "Pick low-sleep recovery mobility or hips/hamstrings.", true),
        item(.meditation, "Meditation / Mental Reset", "Stress control is part of the plan, not an optional extra.", "Choose one", meditationOptions, "Use 2 minutes now rather than waiting for perfect quiet.", true),
        item(.cronometer, "Cronometer / Nutrition Tracking", "Keep nutrition visible while the training dial is lower.", "Simple rule", ["Log protein and the main meals.", "Do not chase perfection."], "Minimum useful tracking is enough.", false),
        item(.protein, "Protein Target", "Protect recovery with a steady protein floor.", "Simple rule", ["Protein at two meals minimum.", "Use a simple backup if appetite is off."], "This is a recovery lever today.", true),
        item(.water, "Water Target", "Hydration is an easy readiness win.", "Simple rule", ["Finish one bottle early.", "Pair water with meals."], "Make this one automatic.", true),
        item(.caffeine, "Caffeine Cutoff", "Keep the afternoon from stealing tonight.", "Cutoff", ["Choose a firm cutoff.", "No heroic late caffeine."], "Energy debt is not solved with more caffeine.", true),
        item(.sleep, "Sleep Routine", "Make sleep protection the closing ritual.", "Shutdown cues", ["Screens down.", "Room cool.", "Tomorrow's first move chosen."], "This is where tomorrow improves.", true),
        item(.dailyWin, "Daily Win", "Capture one clean win.", "Prompt", ["What did you protect today?"], "Small counts.", false)
    ]

    static let recoveryItems: [RitualItem] = [
        item(.movement, "Movement / Steps", "Walking is recovery work today.", "Today's target", ["Keep it conversational.", "Split it into short walks if needed."], "Walk to feel better, not to prove fitness.", true),
        item(.mobility, "Stretching & Mobility", "Gentle range of motion is the priority.", "Choose one", mobilityOptions, "Low-sleep recovery mobility is the default today.", true),
        item(.meditation, "Meditation / Mental Reset", "Let the system come down.", "Choose one", meditationOptions, "Try the 3-minute body scan.", true),
        item(.protein, "Protein Target", "Recovery still needs inputs.", "Simple rule", ["Hit protein without making food complicated."], "Support repair. Keep it simple.", true),
        item(.water, "Water Target", "Hydration helps the body settle.", "Simple rule", ["Steady water across the day.", "Add electrolytes if needed."], "Quiet consistency.", true),
        item(.caffeine, "Caffeine Cutoff", "Earlier cutoff, better recovery.", "Cutoff", ["Move caffeine earlier than usual.", "Let tired be information."], "Do not borrow from tomorrow.", true),
        item(.sleep, "Sleep Routine", "The main ritual is protecting sleep.", "Shutdown cues", ["Set a hard wind-down.", "Dim lights.", "No late work spiral."], "Recovery Day succeeds at night.", true),
        item(.dailyWin, "Daily Win", "Name the recovery win.", "Prompt", ["Where did you choose restraint?"], "Restraint counts.", false)
    ]

    static let bareMinimumItems: [RitualItem] = [
        item(.movement, "Tiny Movement", "Move for a few minutes so the chain stays alive.", "Minimum", ["Walk or march for 5 minutes.", "Stop while it still feels easy."], "The smallest useful dose is the mission.", true),
        item(.water, "Water", "Get one basic hydration win.", "Minimum", ["Finish one bottle or two large glasses."], "Simple, physical, done.", true),
        item(.protein, "Protein", "Give the body one solid anchor.", "Minimum", ["Get one protein-centered meal or shake."], "One anchor beats a vague perfect plan.", true),
        item(.meditation, "2-Minute Reset", "Take the edge off the day.", "Instructions", ["Inhale for 4.", "Exhale for 6.", "Repeat for 2 minutes."], "No setup. Just breathe.", true),
        item(.sleep, "Early Off-Ramp", "End the day without making it worse.", "Minimum", ["Pick a shutdown time.", "Put the phone away before bed."], "Protect tomorrow.", true),
        item(.dailyWin, "Daily Win", "One sentence is enough.", "Prompt", ["What did you keep from sliding today?"], "Make it count, then let it be done.", false)
    ]

    static let meditationOptions = [
        "2-minute breathing reset: inhale 4, exhale 6, repeat calmly.",
        "3-minute body scan: soften jaw, shoulders, ribs, hips, legs.",
        "5-minute gratitude/reflection: name one win, one lesson, one thing to release."
    ]

    static let mobilityOptions = [
        "5-minute daily mobility: cat-camel, hip flexor stretch, hamstring floss, child pose breathing.",
        "Low-sleep recovery mobility: easy walk, gentle hips, supine breathing.",
        "Shoulder/neck reset: chin tucks, wall slides, band pull-aparts, slow neck turns.",
        "Hips/hamstrings reset: 90/90 switches, hinge drill, hamstring floss, glute bridge."
    ]

    static func item(
        _ kind: RitualItemKind,
        _ title: String,
        _ description: String,
        _ detailTitle: String,
        _ details: [String],
        _ recommendation: String,
        _ isRequired: Bool
    ) -> RitualItem {
        RitualItem(
            id: kind.rawValue
                .lowercased()
                .replacingOccurrences(of: " / ", with: "-")
                .replacingOccurrences(of: " ", with: "-"),
            kind: kind,
            title: title,
            description: description,
            detailTitle: detailTitle,
            details: details,
            recommendation: recommendation,
            isRequired: isRequired
        )
    }
}
