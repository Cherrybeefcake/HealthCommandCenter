import Foundation

struct ReadinessResult {
    let score: Int
    let category: ReadinessCategory
    let reasons: [String]
}

struct ReadinessClassifier {
    func classify(
        energy: Int,
        soreness: Int,
        stress: Int,
        mood: Int,
        availableWorkoutMinutes: Int,
        painNote: String,
        health: HealthSnapshot,
        oura: OuraDailySummary?
    ) -> ReadinessResult {
        var score = 50
        score += (energy - 5) * 5
        score += (mood - 5) * 3
        score -= max(0, soreness - 4) * 4
        score -= max(0, stress - 4) * 4

        if availableWorkoutMinutes >= 60 { score += 8 }
        if availableWorkoutMinutes < 25 { score -= 10 }
        if !painNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score -= 18 }

        if let sleepHours = health.sleepHours {
            if sleepHours >= 7.5 { score += 8 }
            if sleepHours < 6 { score -= 10 }
        }

        if let hrv = health.hrvSDNN {
            if hrv >= 60 { score += 5 }
            if hrv < 30 { score -= 6 }
        }

        if let restingHeartRate = health.restingHeartRate, restingHeartRate > 72 {
            score -= 5
        }

        if let ouraScore = oura?.readinessScore {
            score = Int(Double(score) * 0.75 + Double(ouraScore) * 0.25)
        }

        score = min(100, max(0, score))
        let category: ReadinessCategory
        switch score {
        case 82...100:
            category = .pushDay
        case 66...81:
            category = .normalTrainingDay
        case 50...65:
            category = .lightTrainingDay
        case 34...49:
            category = .recoveryDay
        default:
            category = .bareMinimumDay
        }

        return ReadinessResult(score: score, category: category, reasons: buildReasons(
            energy: energy,
            soreness: soreness,
            stress: stress,
            mood: mood,
            availableWorkoutMinutes: availableWorkoutMinutes,
            painNote: painNote,
            health: health,
            oura: oura
        ))
    }

    private func buildReasons(
        energy: Int,
        soreness: Int,
        stress: Int,
        mood: Int,
        availableWorkoutMinutes: Int,
        painNote: String,
        health: HealthSnapshot,
        oura: OuraDailySummary?
    ) -> [String] {
        var reasons: [String] = []

        if energy >= 8 {
            reasons.append("Energy is high enough to support more work.")
        } else if energy <= 4 {
            reasons.append("Energy is low, so the day needs a smaller target.")
        }

        if soreness >= 7 {
            reasons.append("Soreness is elevated, which lowers training readiness.")
        }

        if stress >= 7 {
            reasons.append("Stress is high, so the plan should protect recovery.")
        }

        if mood >= 7 {
            reasons.append("Mood is steady, which supports follow-through.")
        } else if mood <= 4 {
            reasons.append("Mood is low, so the mission favors consistency over intensity.")
        }

        if availableWorkoutMinutes < 25 {
            reasons.append("Available workout time is short today.")
        } else if availableWorkoutMinutes >= 60 {
            reasons.append("You have enough time for a complete session.")
        }

        if !painNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            reasons.append("You reported pain or a problem, so intensity is capped.")
        }

        if let sleepHours = health.sleepHours {
            if sleepHours >= 7.5 {
                reasons.append("Sleep duration is supportive.")
            } else if sleepHours < 6 {
                reasons.append("Sleep is short, which pulls the mission toward recovery.")
            }
        }

        if let hrv = health.hrvSDNN, hrv < 30 {
            reasons.append("HRV is muted compared with a strong recovery signal.")
        }

        if let restingHeartRate = health.restingHeartRate, restingHeartRate > 72 {
            reasons.append("Resting heart rate is elevated.")
        }

        if oura?.readinessScore != nil {
            reasons.append("Oura readiness was included from the service layer.")
        }

        if reasons.isEmpty {
            reasons.append("The category comes mostly from your subjective check-in because wearable data is limited today.")
        }

        return Array(reasons.prefix(4))
    }
}
