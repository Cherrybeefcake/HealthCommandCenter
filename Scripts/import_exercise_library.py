#!/usr/bin/env python3
import json
import re
from datetime import date
from pathlib import Path

SOURCE_URL = "https://github.com/yuhonas/free-exercise-db"
SOURCE_NAME = "yuhonas/free-exercise-db"
SOURCE_LICENSE = "Unlicense / Public Domain"

ROOT = Path(__file__).resolve().parents[1]
SOURCE_JSON = Path("/private/tmp/hcc-exercise-import/free-exercise-db-main/dist/exercises.json")
OUTPUT_JSON = ROOT / "HealthCommandCenter" / "Resources" / "ImportedExerciseLibrary.json"


def slug(text):
    text = text.lower().replace("&", "and")
    text = re.sub(r"[^a-z0-9]+", "-", text).strip("-")
    return text or "exercise"


MUSCLE_MAP = {
    "abdominals": "Core",
    "abductors": "Hips",
    "adductors": "Hips",
    "biceps": "Biceps",
    "calves": "Calves",
    "chest": "Chest",
    "forearms": "Biceps",
    "glutes": "Glutes",
    "hamstrings": "Hamstrings",
    "lats": "Back",
    "lower back": "Back",
    "middle back": "Back",
    "neck": "Neck",
    "quadriceps": "Quads",
    "shoulders": "Shoulders",
    "traps": "Back",
    "triceps": "Triceps",
}

EQUIPMENT_MAP = {
    None: "Other",
    "": "Other",
    "bands": "Resistance Bands",
    "barbell": "Barbell",
    "body only": "Bodyweight",
    "cable": "Cable",
    "dumbbell": "Dumbbells",
    "e-z curl bar": "EZ Curl Bar",
    "exercise ball": "Exercise Ball",
    "foam roll": "Foam Roll",
    "kettlebells": "Kettlebells",
    "machine": "Machine",
    "medicine ball": "Medicine Ball",
    "other": "Other",
}


def muscles(values):
    mapped = []
    for value in values or []:
        muscle = MUSCLE_MAP.get(str(value).lower(), "Full Body")
        if muscle not in mapped:
            mapped.append(muscle)
    return mapped or ["Full Body"]


def equipment(value):
    return [EQUIPMENT_MAP.get(value, "Other")]


def difficulty(level):
    return {
        "beginner": "Beginner",
        "intermediate": "Moderate",
        "expert": "Advanced",
    }.get(level or "", "Beginner")


def category_and_pattern(raw):
    name = raw.get("name", "").lower()
    source_category = (raw.get("category") or "").lower()
    equip = (raw.get("equipment") or "").lower()
    primary = " ".join(raw.get("primaryMuscles") or []).lower()
    force = (raw.get("force") or "").lower()

    if source_category == "stretching" or "stretch" in name or "mobility" in name:
        return "Mobility", "Mobility"
    if "bike" in name:
        return "Bike", "Conditioning"
    if "stair" in name or "walk" in name or source_category == "cardio":
        return "Stairs", "Conditioning"
    if equip == "bands":
        return "Bands", infer_pattern(name, primary, force)
    if equip == "dumbbell":
        return "Dumbbells", infer_pattern(name, primary, force)
    if "squat" in name:
        return "Squat", "Squat"
    if any(token in name for token in ["deadlift", "good morning", "hip thrust", "bridge"]):
        return "Hinge", "Hinge"
    if any(token in name for token in ["lunge", "split squat", "step-up"]):
        return "Squat", "Lunge"
    if any(token in name for token in ["press", "push", "dip", "fly"]):
        return "Push", "Push"
    if any(token in name for token in ["row", "pull", "chin", "curl"]):
        return "Pull", "Pull"
    if any(token in name for token in ["carry", "walk"]):
        return "Carry", "Carry"
    if any(token in primary for token in ["abdominals", "lower back"]) or any(token in name for token in ["crunch", "sit-up", "plank", "rollout"]):
        return "Core", "Core"
    return "Other", infer_pattern(name, primary, force)


def infer_pattern(name, primary, force):
    if any(token in name for token in ["squat", "leg press"]):
        return "Squat"
    if any(token in name for token in ["deadlift", "hinge", "bridge", "hip thrust"]):
        return "Hinge"
    if any(token in name for token in ["lunge", "step-up", "split"]):
        return "Lunge"
    if any(token in name for token in ["press", "push", "fly", "dip"]) or force == "push":
        return "Push"
    if any(token in name for token in ["row", "pull", "curl", "chin"]) or force == "pull":
        return "Pull"
    if any(token in primary for token in ["abdominals", "lower back"]):
        return "Core"
    return "Other"


def locations(equipment_values, category):
    values = set(equipment_values)
    if category in {"Mobility", "Recovery"}:
        return ["Home", "Work", "Gym", "Outside", "Mixed"]
    if values & {"Dumbbells", "Resistance Bands", "Bodyweight", "Mat", "Exercise Ball"}:
        return ["Home", "Work", "Gym", "Mixed"]
    if values & {"Barbell", "Cable", "Machine", "EZ Curl Bar"}:
        return ["Work", "Gym", "Mixed"]
    if category in {"Bike", "Stairs"}:
        return ["Work", "Gym", "Outside", "Mixed"]
    return ["Gym", "Mixed"]


def imported_record(raw):
    category, pattern = category_and_pattern(raw)
    primary = muscles(raw.get("primaryMuscles"))
    secondary = muscles(raw.get("secondaryMuscles")) if raw.get("secondaryMuscles") else []
    equip = equipment(raw.get("equipment"))
    instructions = [x.strip() for x in raw.get("instructions") or [] if x and x.strip()]
    setup = instructions[0] if instructions else f"Set up for {raw.get('name', 'this exercise')} with control."
    steps = instructions[1:] or instructions or ["Move with control.", "Stop before form gets noisy."]
    name = raw.get("name", "Unnamed Exercise")
    lower = name.lower()
    shoulder_friendly = not any(token in lower for token in ["overhead", "behind neck", "upright row", "snatch", "jerk"])
    low_back_friendly = not any(token in lower for token in ["deadlift", "good morning", "hyperextension", "clean", "snatch"])
    aliases = sorted(set([raw.get("id", ""), name.replace("-", " "), name.replace("_", " ")]))

    return {
        "id": f"free-db-{slug(raw.get('id') or name)}",
        "name": name,
        "category": category,
        "aliases": [x for x in aliases if x and x != name],
        "movementPattern": pattern,
        "primaryMuscles": primary,
        "secondaryMuscles": secondary,
        "equipment": equip,
        "difficulty": difficulty(raw.get("level")),
        "force": raw.get("force"),
        "mechanic": raw.get("mechanic"),
        "setup": setup,
        "executionSteps": steps[:8],
        "breathingCue": "Breathe steadily through the controlled part of the rep; avoid holding breath unless coached.",
        "commonMistakes": ["Rushing the setup.", "Chasing load before range and control are steady."],
        "howItShouldFeel": "Controlled effort in the target muscles without sharp joint pain.",
        "painCautionGuidance": "Stop or substitute if pain sharpens, radiates, or changes the movement.",
        "variations": [],
        "substitutions": [],
        "locationCompatibility": locations(equip, category),
        "isShoulderFriendly": shoulder_friendly,
        "isLowBackFriendly": low_back_friendly,
        "sourceName": SOURCE_NAME,
        "sourceLicense": SOURCE_LICENSE,
        "sourceURL": f"{SOURCE_URL}/blob/main/exercises/{raw.get('id', '')}.json",
        "importedAt": date.today().isoformat(),
    }


band_patterns = [
    ("squat", "Squat", "Quads", "Glutes"), ("hinge", "Hinge", "Hamstrings", "Glutes"), ("lunge", "Lunge", "Quads", "Glutes"),
    ("chest press", "Push", "Chest", "Triceps"), ("fly", "Push", "Chest", "Shoulders"), ("push-up assistance", "Push", "Chest", "Triceps"),
    ("row", "Pull", "Back", "Biceps"), ("pulldown", "Pull", "Back", "Biceps"), ("pullover", "Pull", "Back", "Chest"),
    ("face pull", "Pull", "Shoulders", "Back"), ("external rotation", "Pull", "Shoulders", "Back"), ("internal rotation", "Push", "Shoulders", "Chest"),
    ("lateral raise", "Push", "Shoulders", "Triceps"), ("front raise", "Push", "Shoulders", "Chest"), ("rear-delt raise", "Pull", "Shoulders", "Back"),
    ("curl", "Pull", "Biceps", "Biceps"), ("triceps pressdown", "Push", "Triceps", "Chest"), ("glute bridge", "Hinge", "Glutes", "Hamstrings"),
    ("hip abduction", "Other", "Hips", "Glutes"), ("hamstring curl", "Hinge", "Hamstrings", "Glutes"), ("quad extension", "Squat", "Quads", "Calves"),
    ("calf raise", "Other", "Calves", "Quads"), ("anti-rotation press", "Core", "Core", "Shoulders"), ("loaded march", "Carry", "Full Body", "Core"),
    ("lateral walk", "Other", "Hips", "Glutes"),
]
band_setups = ["long band anchored low", "long band anchored chest height", "long band unanchored", "mini-band above knees"]


def band_records():
    records = []
    for setup in band_setups:
        for movement, pattern, primary, secondary in band_patterns:
            name = f"{setup.title()} {movement.title()}"
            records.append(curated_record(
                prefix="hcc-band",
                name=name,
                category="Bands",
                pattern=pattern,
                primary=[primary],
                secondary=[secondary],
                equipment=["Resistance Bands"],
                setup=f"Use a {setup}. Start with light tension and a stance that lets Brian own the range.",
                steps=[
                    "Create gentle band tension before the first rep.",
                    "Move through a clean range without snapping the band.",
                    "Pause briefly where the target muscle is working.",
                    "Return slowly and reset posture before the next rep.",
                ],
                breathing="Exhale through the effort, inhale on the return.",
                feel="Target muscles work with joint-friendly tension and no sharp pull from the band.",
                caution="Check the anchor before every set. Avoid aggressive range if shoulder, neck, knee, or back pain appears.",
                substitutions=[{"id": "lighter-band", "name": "Lighter Band", "reason": "Use when form or joints need a lower floor."}],
            ))
    return records[:100]


mobility_regions = [
    ("neck", "Neck"), ("chest", "Chest"), ("shoulders", "Shoulders"), ("upper back", "Back"), ("thoracic rotation", "Back"),
    ("thoracic extension", "Back"), ("wrists", "Biceps"), ("forearms", "Biceps"), ("low-back-friendly", "Back"), ("hips", "Hips"),
    ("hip flexors", "Hips"), ("glutes", "Glutes"), ("piriformis", "Glutes"), ("hamstrings", "Hamstrings"), ("quads", "Quads"),
    ("adductors", "Hips"), ("calves", "Calves"), ("ankles", "Calves"), ("full-body warmup", "Full Body"), ("cooldown", "Full Body"),
    ("desk reset", "Neck"), ("work reset", "Shoulders"), ("pre-sleep flow", "Full Body"), ("shoulder-friendly flow", "Shoulders"), ("low-sleep recovery", "Full Body"),
]
mobility_styles = ["breathing reset", "dynamic prep", "gentle stretch", "floor flow"]


def mobility_records():
    records = []
    for style in mobility_styles:
        for region, primary in mobility_regions:
            name = f"{region.title()} {style.title()}"
            records.append(curated_record(
                prefix="hcc-mobility",
                name=name,
                category="Mobility" if "prep" in style or "stretch" in style else "Recovery",
                pattern="Mobility" if "prep" in style or "stretch" in style else "Recovery",
                primary=[primary],
                secondary=["Core"] if primary != "Core" else [],
                equipment=["Bodyweight", "Mat"],
                setup=f"Set a calm position for the {region} and keep intensity below a hard stretch.",
                steps=[
                    "Start with one slow breath before moving.",
                    "Move into the first easy range.",
                    "Hold or pulse gently for the prescribed time.",
                    "Back out slowly and reassess before repeating.",
                ],
                breathing="Use long exhales and keep the jaw, neck, and shoulders easy.",
                feel="Mild stretch or warmth, never sharp pain, tingling, or pressure.",
                caution="Avoid forcing end range. Stop if symptoms sharpen, radiate, or linger.",
                substitutions=[{"id": "shorter-range", "name": "Shorter Range", "reason": "Use on low-sleep or high-stress days."}],
            ))
    return records[:100]


def curated_record(prefix, name, category, pattern, primary, secondary, equipment, setup, steps, breathing, feel, caution, substitutions):
    return {
        "id": f"{prefix}-{slug(name)}",
        "name": name,
        "category": category,
        "aliases": [name.replace("Long Band", "Band"), name.replace("Mini-Band", "Band")],
        "movementPattern": pattern,
        "primaryMuscles": primary,
        "secondaryMuscles": secondary,
        "equipment": equipment,
        "difficulty": "Starter",
        "force": None,
        "mechanic": None,
        "setup": setup,
        "executionSteps": steps,
        "breathingCue": breathing,
        "commonMistakes": ["Moving too fast.", "Forcing range or tension.", "Ignoring anchor/setup quality."],
        "howItShouldFeel": feel,
        "painCautionGuidance": caution,
        "variations": [],
        "substitutions": substitutions,
        "locationCompatibility": ["Home", "Work", "Gym", "Mixed"],
        "isShoulderFriendly": "overhead" not in name.lower(),
        "isLowBackFriendly": "deadlift" not in name.lower() and "hinge" not in name.lower(),
        "sourceName": "Health Command Center curated extension",
        "sourceLicense": "HCC project curated content",
        "sourceURL": None,
        "importedAt": date.today().isoformat(),
    }


def main():
    raw = json.loads(SOURCE_JSON.read_text())
    records = [imported_record(item) for item in raw]
    records.extend(band_records())
    records.extend(mobility_records())
    OUTPUT_JSON.write_text(json.dumps(records, indent=2, sort_keys=True) + "\n")
    print(f"wrote {len(records)} records to {OUTPUT_JSON}")
    print(f"imported={len(raw)} band={len(band_records())} mobility={len(mobility_records())}")


if __name__ == "__main__":
    main()
