import sys
import json
import os
import joblib
import numpy as np
import warnings

warnings.filterwarnings('ignore')

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No symptoms provided"}))
        sys.exit(1)

    input_symptoms_csv = sys.argv[1]
    input_symptoms = [s.strip().lower() for s in input_symptoms_csv.split(',')]

    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.abspath(os.path.join(script_dir, ".."))
    json_path = os.path.join(project_root, "dataset", "medical_data.json")
    model_path = os.path.join(script_dir, "triage_absolute_best_model.pkl")

    # Load symptoms universe
    try:
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        print(json.dumps({"error": f"Failed to read dataset: {e}"}))
        sys.exit(1)

    all_symptoms = set()
    for record in data:
        for symptom in record.get("symptoms", []):
            all_symptoms.add(symptom.strip().lower())
    all_symptoms = sorted(list(all_symptoms))

    # Build feature vector
    input_symptoms_set = set(input_symptoms)
    feature_vector = [1 if sym in input_symptoms_set else 0 for sym in all_symptoms]
    count = sum(feature_vector)
    ratio = count / len(all_symptoms) if len(all_symptoms) > 0 else 0
    feature_vector.extend([count, ratio])

    X_test = np.array([feature_vector])

    # Load model and predict
    try:
        model = joblib.load(model_path)
    except Exception as e:
        print(json.dumps({"error": f"Failed to load model: {e}"}))
        sys.exit(1)

    # Note: Label encoding used during training: 0, 1, 2 = Kirmizi, Sari, Yesil (Alphabetical: KIRMIZI, SARI, YESIL usually, let's check classes order)
    # The le.classes_ output from before was: ['Kirmizi', 'Sari', 'Yesil']
    try:
        probs = model.predict_proba(X_test)[0]
        pred_idx = np.argmax(probs)
        
        classes = ['Kirmizi', 'Sari', 'Yesil']
        color = classes[pred_idx].upper()
        confidence = int(probs[pred_idx] * 100)

        critical_symptoms = [sym for sym in input_symptoms if sym in all_symptoms]
        explanation = f"AI Algoritması {color} Kodu ({confidence}%) olarak sınıflandırdı. Saptanan anahtarlar: {', '.join(critical_symptoms)}"
        
        result = {
            "color": color,
            "confidence": confidence,
            "explanation": explanation
        }
        
        print(json.dumps(result))

    except Exception as e:
        print(json.dumps({"error": f"Prediction failed: {e}"}))
        sys.exit(1)

if __name__ == "__main__":
    main()
