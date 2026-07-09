import Foundation

enum ProgramPhase: String, Codable, CaseIterable, Identifiable {
    case nightShift = "Night Shift"
    case dayShift = "Day Shift"
    case newBaby = "New-Baby"
    case normalRoutine = "Normal Routine"

    var id: String { rawValue }
}

enum TrainingLocation: String, Codable, CaseIterable, Identifiable {
    case home = "Home"
    case work = "Work"
    case gym = "Gym"
    case outside = "Outside"
    case mixed = "Mixed"

    var id: String { rawValue }
}

enum WorkoutTimePreference: String, Codable, CaseIterable, Identifiable {
    case beginningOfShift = "Beginning of shift"
    case afterShift = "After shift"
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case flexible = "Flexible"

    var id: String { rawValue }
}

struct NutritionTargets: Hashable {
    let goal: String
    let proteinGrams: Int
    let waterOunces: Int
    let fiberGuidance: String
    let avoids: String
    let proteinPowder: String
    let creatine: String

    static let brianDefault = NutritionTargets(
        goal: "Body recomposition",
        proteinGrams: 160,
        waterOunces: 100,
        fiberGuidance: "25-35g/day as tolerated",
        avoids: "Seafood and mushrooms",
        proteinPowder: "Yes",
        creatine: "Interested / open"
    )

    static func from(_ profile: PersonalizationSettings) -> NutritionTargets {
        NutritionTargets(
            goal: profile.goal,
            proteinGrams: profile.proteinTargetGrams,
            waterOunces: profile.waterTargetOunces,
            fiberGuidance: "25-35g/day as tolerated",
            avoids: profile.avoidanceText,
            proteinPowder: "Yes",
            creatine: "Interested / open"
        )
    }
}

struct PersonalizationSettings: Codable, Hashable {
    var goal: String
    var heightText: String
    var startingWeightPounds: Double?
    var equipmentConfirmed: Bool
    var avoidsSeafood: Bool
    var avoidsMushrooms: Bool
    var proteinTargetGrams: Int
    var waterTargetOunces: Int

    static let brianDefault = PersonalizationSettings(
        goal: "Body recomposition / look better / feel better / get stronger",
        heightText: "5'6\"",
        startingWeightPounds: 174,
        equipmentConfirmed: true,
        avoidsSeafood: true,
        avoidsMushrooms: true,
        proteinTargetGrams: 160,
        waterTargetOunces: 100
    )

    var baselineText: String {
        let weight = startingWeightPounds.map { String(format: "around %.0f lb", $0) } ?? "starting weight open"
        return "\(heightText) | \(weight) | restarting training"
    }

    var avoidanceText: String {
        var avoids: [String] = []
        if avoidsSeafood { avoids.append("seafood") }
        if avoidsMushrooms { avoids.append("mushrooms") }
        return avoids.isEmpty ? "No avoidances set" : avoids.joined(separator: " and ")
    }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case workMeal = "Work meal"
    case shake = "Shake"

    var id: String { rawValue }
}

struct MealTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let mealType: MealType
    let proteinIdea: String
    let carbIdea: String
    let fruitOrVegetableIdea: String
    let fatIdea: String
    let prepNotes: String
    let tags: [String]
    let avoidsSeafoodAndMushrooms: Bool

    init(
        id: String,
        title: String,
        mealType: MealType,
        proteinIdea: String,
        carbIdea: String,
        fruitOrVegetableIdea: String,
        fatIdea: String,
        prepNotes: String,
        tags: [String],
        avoidsSeafoodAndMushrooms: Bool = true
    ) {
        self.id = id
        self.title = title
        self.mealType = mealType
        self.proteinIdea = proteinIdea
        self.carbIdea = carbIdea
        self.fruitOrVegetableIdea = fruitOrVegetableIdea
        self.fatIdea = fatIdea
        self.prepNotes = prepNotes
        self.tags = tags
        self.avoidsSeafoodAndMushrooms = avoidsSeafoodAndMushrooms
    }
}

struct MealTemplateLibrary {
    static let templates: [MealTemplate] = [
        MealTemplate(
            id: "work-griddle-meal",
            title: "Work griddle meal",
            mealType: .workMeal,
            proteinIdea: "Chicken breast, lean beef, turkey patties, or eggs",
            carbIdea: "Rice cup, potatoes, wrap, or toast",
            fruitOrVegetableIdea: "Bagged salad, peppers, onions, fruit cup, or berries",
            fatIdea: "Avocado cup, olive oil spray, or cheese",
            prepNotes: "Built for work: griddle protein, fridge carbs/produce, simple cleanup.",
            tags: ["work", "griddle", "high protein"]
        ),
        MealTemplate(
            id: "protein-shake",
            title: "Protein shake",
            mealType: .shake,
            proteinIdea: "Protein powder plus milk or Greek yogurt",
            carbIdea: "Banana, oats, or frozen berries",
            fruitOrVegetableIdea: "Berries or banana",
            fatIdea: "Peanut butter or chia if needed",
            prepNotes: "Blender-friendly. Use when appetite or time is low.",
            tags: ["fast", "blender", "low friction"]
        ),
        MealTemplate(
            id: "greek-yogurt-bowl",
            title: "Greek yogurt bowl",
            mealType: .breakfast,
            proteinIdea: "Greek yogurt or skyr",
            carbIdea: "Granola, oats, or cereal",
            fruitOrVegetableIdea: "Berries, banana, or apple",
            fatIdea: "Nuts, chia, or peanut butter",
            prepNotes: "No-cook bowl for breakfast, snack, or post-shift.",
            tags: ["no cook", "fiber", "protein"]
        ),
        MealTemplate(
            id: "eggs-turkey-sausage-toast",
            title: "Eggs, turkey sausage, toast",
            mealType: .breakfast,
            proteinIdea: "Eggs plus turkey sausage",
            carbIdea: "Toast, English muffin, or potatoes",
            fruitOrVegetableIdea: "Fruit or spinach/peppers",
            fatIdea: "Avocado or cheese if it fits",
            prepNotes: "Easy home breakfast that still supports protein.",
            tags: ["home", "breakfast", "griddle"]
        ),
        MealTemplate(
            id: "chicken-rice-vegetables",
            title: "Chicken, rice, vegetables",
            mealType: .lunch,
            proteinIdea: "Chicken breast or thighs",
            carbIdea: "Rice, potatoes, or quinoa",
            fruitOrVegetableIdea: "Broccoli, green beans, peppers, carrots, or salad",
            fatIdea: "Olive oil, avocado, or light sauce",
            prepNotes: "Batch-friendly and easy to log in Cronometer.",
            tags: ["batch", "simple", "work"]
        ),
        MealTemplate(
            id: "burger-bowl",
            title: "Beef or turkey burger bowl",
            mealType: .dinner,
            proteinIdea: "Lean beef or turkey burger",
            carbIdea: "Potatoes, rice, or bun pieces",
            fruitOrVegetableIdea: "Lettuce, tomato, pickles, onions, or slaw",
            fatIdea: "Cheese, avocado, or sauce measured simply",
            prepNotes: "Family-friendly plate without needing a separate diet meal.",
            tags: ["family", "dinner", "high protein"]
        ),
        MealTemplate(
            id: "turkey-chicken-wrap",
            title: "Turkey or chicken wrap",
            mealType: .lunch,
            proteinIdea: "Turkey, chicken, or deli-style lean meat",
            carbIdea: "High-fiber wrap or tortilla",
            fruitOrVegetableIdea: "Lettuce, peppers, cucumber, fruit on the side",
            fatIdea: "Cheese, avocado, or hummus",
            prepNotes: "Portable and low-friction for shifts.",
            tags: ["portable", "work", "quick"]
        ),
        MealTemplate(
            id: "cottage-cheese-snack",
            title: "Cottage cheese snack",
            mealType: .snack,
            proteinIdea: "Cottage cheese",
            carbIdea: "Crackers, toast, or cereal",
            fruitOrVegetableIdea: "Fruit, berries, or tomatoes/cucumber",
            fatIdea: "Nuts or avocado if needed",
            prepNotes: "Use as a protein bridge when dinner is far away.",
            tags: ["snack", "no cook", "protein"]
        ),
        MealTemplate(
            id: "protein-oatmeal",
            title: "Protein oatmeal",
            mealType: .breakfast,
            proteinIdea: "Protein powder or Greek yogurt stirred in",
            carbIdea: "Oats",
            fruitOrVegetableIdea: "Banana, berries, or apple",
            fatIdea: "Peanut butter, nuts, or chia",
            prepNotes: "Warm, filling, and easy to adjust.",
            tags: ["breakfast", "fiber", "steady"]
        ),
        MealTemplate(
            id: "simple-family-dinner",
            title: "Simple family dinner plate",
            mealType: .dinner,
            proteinIdea: "Chicken, turkey, lean beef, pork, eggs, or tofu",
            carbIdea: "Rice, pasta, potatoes, bread, or tortillas",
            fruitOrVegetableIdea: "Any produce on the table",
            fatIdea: "Sauce, cheese, avocado, olive oil, or nuts",
            prepNotes: "No separate meal required: build the plate from what is already there.",
            tags: ["family", "flexible", "no rigid plan"]
        )
    ]

    static var todaySuggestions: [MealTemplate] {
        Array(templates.prefix(5))
    }
}

enum RecoveryCategory: String, Hashable {
    case strong = "Strong"
    case okay = "Okay"
    case limited = "Limited"
    case poor = "Poor"
    case unknown = "Unknown"
}

struct RecoveryStatus: Hashable {
    let sleepDurationText: String
    let sleepSourceText: String
    let sleepDetailText: String
    let supportingContextText: String
    let subjectiveOverrideText: String?
    let sleepQualityText: String
    let recoveryCategory: RecoveryCategory
    let trainingAdjustmentText: String
    let caffeineGuidance: String
    let windDownGuidance: String
    let napGuidance: String
    let coachingLine: String
}

struct DailyChartPoint: Identifiable, Hashable {
    let id: String
    let dateKey: String
    let label: String
    let value: Double
    let secondaryValue: Double?
    let detail: String

    var hasValue: Bool {
        value > 0 || (secondaryValue ?? 0) > 0
    }
}

struct DeviceStatusItem: Identifiable, Hashable {
    let id: String
    let title: String
    let value: String
    let detail: String
}

struct ReminderTime: Codable, Hashable {
    var hour: Int
    var minute: Int

    static let checkInDefault = ReminderTime(hour: 8, minute: 0)
    static let ritualDefault = ReminderTime(hour: 18, minute: 30)
    static let sleepDefault = ReminderTime(hour: 21, minute: 30)
    static let nutritionDefault = ReminderTime(hour: 19, minute: 30)

    var dateComponents: DateComponents {
        DateComponents(hour: hour, minute: minute)
    }

    var displayText: String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let calendar = Calendar.current
        let date = calendar.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    func date(on baseDate: Date = Date()) -> Date {
        let calendar = Calendar.current
        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: baseDate
        ) ?? baseDate
    }

    static func from(date: Date) -> ReminderTime {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return ReminderTime(hour: components.hour ?? 8, minute: components.minute ?? 0)
    }
}

struct ReminderSettings: Codable, Hashable {
    var remindersEnabled: Bool
    var checkInReminderEnabled: Bool
    var checkInReminderTime: ReminderTime
    var ritualReminderEnabled: Bool
    var ritualReminderTime: ReminderTime
    var sleepReminderEnabled: Bool
    var sleepReminderTime: ReminderTime
    var nutritionReminderEnabled: Bool
    var nutritionReminderTime: ReminderTime

    static let `default` = ReminderSettings(
        remindersEnabled: false,
        checkInReminderEnabled: true,
        checkInReminderTime: .checkInDefault,
        ritualReminderEnabled: true,
        ritualReminderTime: .ritualDefault,
        sleepReminderEnabled: true,
        sleepReminderTime: .sleepDefault,
        nutritionReminderEnabled: false,
        nutritionReminderTime: .nutritionDefault
    )
}

struct DailyNutritionLog: Codable, Identifiable, Hashable {
    var id: String { dateKey }
    let dateKey: String
    var caloriesLogged: Int?
    var proteinGrams: Int?
    var waterOunces: Int?
    var fiberGrams: Int?
    var cronometerCompleted: Bool
    var proteinTargetHit: Bool
    var waterTargetHit: Bool
    var notes: String
    var updatedAt: Date

    init(
        dateKey: String = RitualLibrary.dateKey(),
        caloriesLogged: Int? = nil,
        proteinGrams: Int? = nil,
        waterOunces: Int? = nil,
        fiberGrams: Int? = nil,
        cronometerCompleted: Bool = false,
        proteinTargetHit: Bool = false,
        waterTargetHit: Bool = false,
        notes: String = "",
        updatedAt: Date = Date()
    ) {
        self.dateKey = dateKey
        self.caloriesLogged = caloriesLogged
        self.proteinGrams = proteinGrams
        self.waterOunces = waterOunces
        self.fiberGrams = fiberGrams
        self.cronometerCompleted = cronometerCompleted
        self.proteinTargetHit = proteinTargetHit
        self.waterTargetHit = waterTargetHit
        self.notes = notes
        self.updatedAt = updatedAt
    }
}
