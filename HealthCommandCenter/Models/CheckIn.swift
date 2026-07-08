import Foundation

struct CheckIn: Codable, Identifiable {
    let id: UUID
    let date: Date
    let energy: Int
    let soreness: Int
    let stress: Int
    let mood: Int
    let availableWorkoutMinutes: Int
    let painNote: String
    let healthSnapshot: HealthSnapshot
    let ouraSummary: OuraDailySummary?
    let readinessScore: Int
    let readinessReasons: [String]
    let category: ReadinessCategory

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case energy
        case soreness
        case stress
        case mood
        case availableWorkoutMinutes
        case painNote
        case healthSnapshot
        case ouraSummary
        case readinessScore
        case readinessReasons
        case category
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        energy: Int,
        soreness: Int,
        stress: Int,
        mood: Int,
        availableWorkoutMinutes: Int,
        painNote: String,
        healthSnapshot: HealthSnapshot,
        ouraSummary: OuraDailySummary?,
        readinessScore: Int,
        readinessReasons: [String] = [],
        category: ReadinessCategory
    ) {
        self.id = id
        self.date = date
        self.energy = energy
        self.soreness = soreness
        self.stress = stress
        self.mood = mood
        self.availableWorkoutMinutes = availableWorkoutMinutes
        self.painNote = painNote
        self.healthSnapshot = healthSnapshot
        self.ouraSummary = ouraSummary
        self.readinessScore = readinessScore
        self.readinessReasons = readinessReasons
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        energy = try container.decode(Int.self, forKey: .energy)
        soreness = try container.decode(Int.self, forKey: .soreness)
        stress = try container.decode(Int.self, forKey: .stress)
        mood = try container.decode(Int.self, forKey: .mood)
        availableWorkoutMinutes = try container.decode(Int.self, forKey: .availableWorkoutMinutes)
        painNote = try container.decode(String.self, forKey: .painNote)
        healthSnapshot = try container.decode(HealthSnapshot.self, forKey: .healthSnapshot)
        ouraSummary = try container.decodeIfPresent(OuraDailySummary.self, forKey: .ouraSummary)
        readinessScore = try container.decode(Int.self, forKey: .readinessScore)
        readinessReasons = try container.decodeIfPresent([String].self, forKey: .readinessReasons) ?? []
        category = try container.decode(ReadinessCategory.self, forKey: .category)
    }
}
