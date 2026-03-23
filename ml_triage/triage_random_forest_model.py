# -*- coding: utf-8 -*-
"""
Acil Servis Triaj - Ileri Seviye Agac Tabanli Modeller (XGBoost, LightGBM, Random Forest)
Hyperparameter Tuning & SMOTE ile Maksimum Basari Optimizasyonu
"""

import json
import os
import warnings
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.model_selection import StratifiedKFold, RandomizedSearchCV
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from imblearn.over_sampling import SMOTE

from sklearn.ensemble import RandomForestClassifier
from xgboost import XGBClassifier
from lightgbm import LGBMClassifier

warnings.filterwarnings('ignore')

plt.rcParams['font.family'] = 'DejaVu Sans'
plt.rcParams['axes.unicode_minus'] = False

print("=" * 60)
print("  TRIAJ SINIFLANDIRMA - ILERI SEVIYE OPTIMIZASYON")
print("=" * 60)

script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, ".."))
json_path = os.path.join(project_root, "dataset", "medical_data.json")
output_dir = script_dir

with open(json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

def map_triage_class(urgency_label):
    label = urgency_label.upper().strip()
    if label == "NORMAL": return "Yesil"
    elif label in ["ACIL", "AC\u0130L", "AC\u0130l"]: return "Sari"
    elif label in ["\u00c7OK ACIL", "\u00c7OK AC\u0130L"]: return "Kirmizi"
    return None

all_symptoms = set()
for record in data:
    for symptom in record.get("symptoms", []):
        all_symptoms.add(symptom.strip().lower())
all_symptoms = sorted(list(all_symptoms))

rows, labels = [], []
for record in data:
    triage = map_triage_class(record["urgency_label"])
    if not triage: continue
    
    record_symptoms = set(s.strip().lower() for s in record.get("symptoms", []))
    feature_vector = [1 if sym in record_symptoms else 0 for sym in all_symptoms]
    count = sum(feature_vector)
    ratio = count / len(all_symptoms) if all_symptoms else 0
    feature_vector.extend([count, ratio])
    
    rows.append(feature_vector)
    labels.append(triage)

extra_cols = all_symptoms + ["symptom_count", "symptom_ratio"]
df = pd.DataFrame(rows, columns=extra_cols)
df["triage_class"] = labels

X = df.drop("triage_class", axis=1).values
y = df["triage_class"].values

le = LabelEncoder()
y_encoded = le.fit_transform(y)

print(f"\nVeri hazir. Toplam: {X.shape[0]} satir, {X.shape[1]} ozellik. Sınıflar: {le.classes_}")

# SMOTE TÜM VERIYE UYGULANIYOR (StratifiedKFold yerine, veri setini bastan cogaltip sonra CV yapalim ki agaclar daha iyi ogrensin)
print("SMOTE uygulaniyor...")
smote = SMOTE(random_state=42)
X_resampled, y_resampled = smote.fit_resample(X, y_encoded)
print(f"SMOTE Sonrasi Toplam: {X_resampled.shape[0]} satir")

# ============================================================
# MODELLER VE PARAMETRE ARAMA UZAYI
# ============================================================
models = {
    "RandomForest": (RandomForestClassifier(random_state=42, class_weight='balanced'), {
        'n_estimators': [100, 300, 500],
        'max_depth': [10, 20, 30, None],
        'min_samples_split': [2, 5, 10],
        'min_samples_leaf': [1, 2, 4]
    }),
    "XGBoost": (XGBClassifier(use_label_encoder=False, eval_metric='mlogloss', random_state=42), {
        'n_estimators': [100, 200, 400],
        'max_depth': [4, 6, 8, 10],
        'learning_rate': [0.01, 0.05, 0.1, 0.2],
        'subsample': [0.6, 0.8, 1.0],
        'colsample_bytree': [0.6, 0.8, 1.0]
    }),
    "LightGBM": (LGBMClassifier(random_state=42, verbose=-1, class_weight='balanced'), {
        'n_estimators': [100, 200, 400],
        'learning_rate': [0.01, 0.05, 0.1, 0.2],
        'num_leaves': [20, 31, 50, 70],
        'max_depth': [5, 10, -1],
        'subsample': [0.6, 0.8, 1.0]
    })
}

best_overall_model = None
best_overall_score = 0
best_overall_name = ""

results_summary = {}

print("\nHyperparameter tuning basliyor (Her model icin 15 rastgele kombinasyon denenecek, 5-Fold Stratified K-Fold)...")

skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)

for name, (model, params) in models.items():
    print(f"\n---> {name} optimize ediliyor...")
    search = RandomizedSearchCV(
        model, param_distributions=params, 
        n_iter=15, cv=skf, scoring='accuracy', 
        verbose=1, random_state=42, n_jobs=-1
    )
    search.fit(X_resampled, y_resampled)
    
    print(f"  En Iyi Parametreler: {search.best_params_}")
    print(f"  En Iyi CV Skoru: %{search.best_score_ * 100:.2f}")
    
    results_summary[name] = search.best_score_
    
    if search.best_score_ > best_overall_score:
        best_overall_score = search.best_score_
        best_overall_model = search.best_estimator_
        best_overall_name = name

print("\n" + "=" * 60)
print(f"  EN IYI MODEL: {best_overall_name} (Acc: %{best_overall_score * 100:.2f})")
print("=" * 60)

# ============================================================
# EN IYI MODELIN 10-FOLD DETAYLI TESTI
# ============================================================
print(f"\n{best_overall_name} modeli uzerinden 10-Fold Orijinal Veri validasyonu yapiliyor...")

N_FOLDS = 10
cv_skf = StratifiedKFold(n_splits=N_FOLDS, shuffle=True, random_state=42)

fold_accs = []
all_y_pred = []
all_y_true = []

for train_idx, test_idx in cv_skf.split(X, y_encoded):
    X_train, X_test = X[train_idx], X[test_idx]
    y_train, y_test = y_encoded[train_idx], y_encoded[test_idx]
    
    # Egitim verisine SMOTE uygula
    sm_train, y_sm_train = SMOTE(random_state=42).fit_resample(X_train, y_train)
    
    # En iyi modelin kopyasini olustur
    from sklearn.base import clone
    fold_model = clone(best_overall_model)
    fold_model.fit(sm_train, y_sm_train)
    
    preds = fold_model.predict(X_test)
    acc = accuracy_score(y_test, preds)
    fold_accs.append(acc)
    
    all_y_true.extend(y_test)
    all_y_pred.extend(preds)

print(f"\nSonuc 10-Fold Ozet:")
print(f"Ortalama Test Acc: %{np.mean(fold_accs)*100:.2f} (+/- %{np.std(fold_accs)*100:.2f})")

print("\n--- BIRLESIK CLASSIFICATION REPORT ---")
print(classification_report(all_y_true, all_y_pred, target_names=le.classes_))

# Confusion Matrix Kaydet
cm = confusion_matrix(all_y_true, all_y_pred)
fig, ax = plt.subplots(figsize=(8, 6))
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
            xticklabels=le.classes_, yticklabels=le.classes_, ax=ax)
plt.title(f'Birlesik Confusion Matrix - {best_overall_name} (Tuned)', fontsize=14, fontweight='bold')
plt.xlabel('Tahmin Edilen Sinif', fontsize=12)
plt.ylabel('Gercek Sinif', fontsize=12)
plt.tight_layout()
plt.savefig(os.path.join(output_dir, "advanced_tuned_confusion_matrix.png"), dpi=150)
plt.close()

# Modeli kaydet
import joblib
final_path = os.path.join(output_dir, "triage_absolute_best_model.pkl")
joblib.dump(best_overall_model, final_path)
print(f"\nTamamen optimize edilmis model kaydedildi: {final_path}")
