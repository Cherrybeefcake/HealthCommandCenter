import Foundation

enum ProgressPhotoAngle: String, Codable, CaseIterable, Identifiable, Hashable {
    case front = "Front"
    case side = "Side"
    case back = "Back"

    var id: String { rawValue }
}

struct ProgressPhotoEntry: Codable, Identifiable, Hashable {
    let id: UUID
    var date: Date
    var angle: ProgressPhotoAngle
    var notes: String
    var imageFileName: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        angle: ProgressPhotoAngle,
        notes: String = "",
        imageFileName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.angle = angle
        self.notes = notes
        self.imageFileName = imageFileName
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case date
        case angle
        case notes
        case imageFileName
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        angle = try container.decodeIfPresent(ProgressPhotoAngle.self, forKey: .angle) ?? .front
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? date
    }
}
