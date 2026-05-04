# -*- coding: utf-8 -*-
"""
Triaj V3 - Text-First Yaklasim + Data Augmentation
%80 hedefi icin koklü degisiklikler:
1. Semptom one-hot KALDIRILDI -> TF-IDF merkezli
2. SVM, MLP, LogReg eklendi (text classification icin ideal)
3. Data augmentation (egitim verisini 3x buyutme)
4. Tum preprocessing SADECE egitim verisine fit
"""
import json, os, warnings, joblib, random
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
from collections import Counter

from sklearn.base import clone
from sklearn.model_selection import StratifiedKFold
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import (accuracy_score, classification_report,
                             confusion_matrix, f1_score)
from sklearn.svm import SVC
from sklearn.linear_model import LogisticRegression, SGDClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.ensemble import (RandomForestClassifier, GradientBoostingClassifier,
                              VotingClassifier, StackingClassifier)
from sklearn.calibration import CalibratedClassifierCV
from imblearn.over_sampling import SMOTE
from xgboost import XGBClassifier
from lightgbm import LGBMClassifier

warnings.filterwarnings('ignore')
random.seed(42)
np.random.seed(42)

def log(msg): print(msg, flush=True)

log("=" * 65)
log("  TRIAJ V3 - TEXT-FIRST + DATA AUGMENTATION")
log("=" * 65)

# ============================================================
# VERI YUKLEME
# ============================================================
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.abspath(os.path.join(script_dir, ".."))
json_path = os.path.join(project_root, "dataset", "medical_data.json")

with open(json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

def map_triage(label):
    label = label.upper().strip()
    if label == "NORMAL": return "Yesil"
    elif label in ["ACIL", "AC\u0130L", "AC\u0130l"]: return "Sari"
    elif label in ["\u00c7OK ACIL", "\u00c7OK AC\u0130L"]: return "Kirmizi"
    return None

# Ham veri hazirligi
records, labels = [], []
for r in data:
    t = map_triage(r["urgency_label"])
    if not t: continue
    symptoms = [s.strip().lower() for s in r.get("symptoms", [])]
    input_text = r.get("input_text", "")
    # Semptomları metin olarak birlestir (TF-IDF icinde yakalanacak)
    combined = input_text + " " + " ".join(symptoms)
    records.append({'text': combined, 'input_text': input_text,
                    'symptoms': symptoms})
    labels.append(t)

le = LabelEncoder()
y = le.fit_transform(labels)
log(f"Veri: {len(records)} kayit, Siniflar: {dict(Counter(labels))}")

# ============================================================
# DATA AUGMENTATION (sadece egitim verisinde kullanilacak)
# ============================================================
def augment_text(text, symptoms):
    """Basit ama etkili text augmentation"""
    augmented = []
    words = text.split()

    # 1. Rastgele kelime silme (%15)
    if len(words) > 3:
        drop_n = max(1, int(len(words) * 0.15))
        indices = list(range(len(words)))
        random.shuffle(indices)
        keep = sorted(indices[drop_n:])
        aug1 = ' '.join([words[i] for i in keep])
        augmented.append(aug1)

    # 2. Kelime sirasi karistirma
    shuffled = words.copy()
    random.shuffle(shuffled)
    augmented.append(' '.join(shuffled))

    # 3. Semptom bazli yeni cumle
    if symptoms:
        random.shuffle(symptoms)
        aug3 = ' '.join(symptoms) + ' ' + text
        augmented.append(aug3)

    return augmented

def augment_fold_data(train_texts, train_y, records_subset):
    """Egitim verisini augment et - azinlik siniflarini daha cok"""
    aug_texts, aug_y = list(train_texts), list(train_y)
    class_counts = Counter(train_y)
    max_count = max(class_counts.values())

    for i, (text, label) in enumerate(zip(train_texts, train_y)):
        # Azinlik siniflarini daha cok augment et
        ratio = max_count / class_counts[label]
        n_aug = min(3, max(1, int(ratio)))

        augs = augment_text(text, list(records_subset[i]['symptoms']))
        for a in augs[:n_aug]:
            aug_texts.append(a)
            aug_y.append(label)

    return aug_texts, np.array(aug_y)

# ============================================================
# KRITIK ANAHTAR KELIMELER
# ============================================================
CRITICAL_KW = [
    'nefes', 'bilinc', 'kanama', 'bayil', 'felc', 'kalp', 'gogus',
    'kaza', 'kirik', 'zehir', 'intihar', 'nobet', 'ates', 'siddetli',
    'ani', 'acil', 'sok', 'travma', 'koma', 'yarali', 'agri',
    'kusma', 'ishal', 'iltihap', 'enfeksiyon', 'sancı', 'krampi'
]

def normalize_tr(text):
    text = text.strip().lower()
    tr_map = str.maketrans('çğıöşüÇĞİÖŞÜ', 'cgiosuCGIOSU')
    return text.translate(tr_map)

def build_extra_features(texts):
    """Ek sayisal ozellikler"""
    feats = []
    for t in texts:
        nt = normalize_tr(t)
        words = t.split()
        kw_count = sum(1 for kw in CRITICAL_KW if kw in nt)
        feats.append([
            len(t), len(words),
            np.mean([len(w) for w in words]) if words else 0,
            kw_count, kw_count / len(CRITICAL_KW),
            t.count('!') + t.count('?'),
            sum(1 for c in t if c.isupper()) / max(len(t), 1),
        ])
    return np.array(feats)

# ============================================================
# MODELLER
# ============================================================
model_configs = {
    "SVM-RBF": SVC(kernel='rbf', C=10, gamma='scale', probability=True,
                   class_weight='balanced', random_state=42),
    "SVM-Linear": SVC(kernel='linear', C=1.0, probability=True,
                      class_weight='balanced', random_state=42),
    "LogReg": LogisticRegression(C=1.0, max_iter=2000, solver='lbfgs',
                                class_weight='balanced', random_state=42),
    "MLP": MLPClassifier(hidden_layer_sizes=(256, 128, 64), max_iter=500,
                         early_stopping=True, validation_fraction=0.1,
                         random_state=42, learning_rate='adaptive'),
    "RF": RandomForestClassifier(n_estimators=500, max_depth=25,
                                 class_weight='balanced', random_state=42, n_jobs=-1),
    "XGBoost": XGBClassifier(n_estimators=400, max_depth=8, learning_rate=0.05,
                             subsample=0.8, eval_metric='mlogloss',
                             random_state=42, verbosity=0),
    "LightGBM": LGBMClassifier(n_estimators=400, learning_rate=0.05, num_leaves=50,
                               class_weight='balanced', random_state=42, verbose=-1),
    "GBM": GradientBoostingClassifier(n_estimators=300, max_depth=6,
                                      learning_rate=0.05, random_state=42),
}

# ============================================================
# 10-FOLD CV (LEAK-PROOF + AUGMENTATION)
# ============================================================
N_FOLDS = 10
skf = StratifiedKFold(n_splits=N_FOLDS, shuffle=True, random_state=42)

texts_arr = np.array([r['text'] for r in records], dtype=object)
records_arr = np.array(records, dtype=object)

log(f"\n{'='*65}")
log(f"  {N_FOLDS}-FOLD CV (TF-IDF Text-First + Augmentation)")
log(f"{'='*65}")

all_results = {}

for model_name, model_template in model_configs.items():
    fold_accs, fold_f1s = [], []
    all_y_true, all_y_pred = [], []

    for fold_i, (train_idx, test_idx) in enumerate(skf.split(texts_arr, y)):
        train_texts_raw = [records[i]['text'] for i in train_idx]
        train_recs = [records[i] for i in train_idx]
        test_texts = [records[i]['text'] for i in test_idx]
        y_train, y_test = y[train_idx], y[test_idx]

        # DATA AUGMENTATION (sadece egitim)
        aug_texts, aug_y = augment_fold_data(train_texts_raw, y_train, train_recs)

        # TF-IDF: SADECE augmented egitim verisine FIT
        tfidf = TfidfVectorizer(max_features=500, ngram_range=(1, 3),
                                sublinear_tf=True, min_df=2, max_df=0.95)
        X_train_tfidf = tfidf.fit_transform(aug_texts).toarray()
        X_test_tfidf = tfidf.transform(test_texts).toarray()

        # Ek features
        X_train_extra = build_extra_features(aug_texts)
        X_test_extra = build_extra_features(test_texts)

        # Scaler: SADECE egitim verisine FIT
        scaler = StandardScaler()
        X_train_extra = scaler.fit_transform(X_train_extra)
        X_test_extra = scaler.transform(X_test_extra)

        X_train = np.hstack([X_train_tfidf, X_train_extra])
        X_test = np.hstack([X_test_tfidf, X_test_extra])

        # Model egitimi (SMOTE yok - augmentation + class_weight yeterli)
        mdl = clone(model_template)
        mdl.fit(X_train, aug_y)

        preds = mdl.predict(X_test)
        acc = accuracy_score(y_test, preds)
        f1 = f1_score(y_test, preds, average='weighted')
        fold_accs.append(acc)
        fold_f1s.append(f1)
        all_y_true.extend(y_test)
        all_y_pred.extend(preds)

    mean_acc = np.mean(fold_accs)
    std_acc = np.std(fold_accs)
    mean_f1 = np.mean(fold_f1s)

    all_results[model_name] = {
        'acc_mean': mean_acc, 'acc_std': std_acc, 'f1_mean': mean_f1,
        'y_true': all_y_true, 'y_pred': all_y_pred
    }
    log(f"  {model_name:20s} | Acc: %{mean_acc*100:.2f} (+/-{std_acc*100:.2f}) | F1w: %{mean_f1*100:.2f}")

# ============================================================
# EN IYI 3 MODEL ILE ENSEMBLE
# ============================================================
log(f"\n{'='*65}")
log("  ENSEMBLE (En Iyi 3 Model)")
log(f"{'='*65}")

sorted_models = sorted(all_results.items(), key=lambda x: x[1]['f1_mean'], reverse=True)
top3_names = [n for n, _ in sorted_models[:3]]
log(f"  Top 3: {top3_names}")

# Voting + Stacking ensemble
for ens_type in ['Voting', 'Stacking']:
    ens_accs, ens_f1s = [], []
    ens_yt, ens_yp = [], []

    for fold_i, (train_idx, test_idx) in enumerate(skf.split(texts_arr, y)):
        train_texts_raw = [records[i]['text'] for i in train_idx]
        train_recs = [records[i] for i in train_idx]
        test_texts = [records[i]['text'] for i in test_idx]
        y_train, y_test = y[train_idx], y[test_idx]

        aug_texts, aug_y = augment_fold_data(train_texts_raw, y_train, train_recs)

        tfidf = TfidfVectorizer(max_features=500, ngram_range=(1, 3),
                                sublinear_tf=True, min_df=2, max_df=0.95)
        X_train = tfidf.fit_transform(aug_texts).toarray()
        X_test = tfidf.transform(test_texts).toarray()

        X_tr_extra = build_extra_features(aug_texts)
        X_te_extra = build_extra_features(test_texts)
        sc = StandardScaler()
        X_tr_extra = sc.fit_transform(X_tr_extra)
        X_te_extra = sc.transform(X_te_extra)

        X_train = np.hstack([X_train, X_tr_extra])
        X_test = np.hstack([X_test, X_te_extra])

        estimators = [(n, clone(model_configs[n])) for n in top3_names]

        if ens_type == 'Voting':
            ens = VotingClassifier(estimators=estimators, voting='soft')
        else:
            ens = StackingClassifier(
                estimators=estimators,
                final_estimator=LogisticRegression(max_iter=1000, random_state=42),
                cv=3, stack_method='predict_proba'
            )

        ens.fit(X_train, aug_y)
        preds = ens.predict(X_test)
        ens_accs.append(accuracy_score(y_test, preds))
        ens_f1s.append(f1_score(y_test, preds, average='weighted'))
        ens_yt.extend(y_test)
        ens_yp.extend(preds)

    name = f"{ens_type}Ensemble"
    all_results[name] = {
        'acc_mean': np.mean(ens_accs), 'acc_std': np.std(ens_accs),
        'f1_mean': np.mean(ens_f1s),
        'y_true': ens_yt, 'y_pred': ens_yp
    }
    log(f"  {name:20s} | Acc: %{np.mean(ens_accs)*100:.2f} (+/-{np.std(ens_accs)*100:.2f}) | F1w: %{np.mean(ens_f1s)*100:.2f}")

# ============================================================
# SONUCLAR
# ============================================================
best_name = max(all_results, key=lambda k: all_results[k]['f1_mean'])
best = all_results[best_name]

log(f"\n{'='*65}")
log(f"  EN IYI: {best_name}")
log(f"  Accuracy: %{best['acc_mean']*100:.2f} (+/-{best['acc_std']*100:.2f})")
log(f"  F1-weighted: %{best['f1_mean']*100:.2f}")
log(f"{'='*65}")

log("\n--- CLASSIFICATION REPORT ---")
log(classification_report(best['y_true'], best['y_pred'], target_names=le.classes_))

# Siralamali tablo
log(f"\n{'='*65}")
log("  TUM SONUCLAR")
log(f"{'='*65}")
sorted_all = sorted(all_results.items(), key=lambda x: x[1]['f1_mean'], reverse=True)
for rank, (name, res) in enumerate(sorted_all, 1):
    marker = " <<<" if name == best_name else ""
    log(f"  {rank:2d}. {name:22s} | Acc: %{res['acc_mean']*100:.2f} | F1w: %{res['f1_mean']*100:.2f}{marker}")

# Confusion Matrix
cm = confusion_matrix(best['y_true'], best['y_pred'])
fig, ax = plt.subplots(figsize=(8, 6))
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
            xticklabels=le.classes_, yticklabels=le.classes_, ax=ax)
plt.title(f'Confusion Matrix - {best_name}', fontsize=12, fontweight='bold')
plt.xlabel('Tahmin'); plt.ylabel('Gercek')
plt.tight_layout()
plt.savefig(os.path.join(script_dir, "confusion_matrix.png"), dpi=150)
plt.close()

# Karsilastirma grafigi
fig, ax = plt.subplots(figsize=(12, 7))
names_s = [n for n, _ in sorted_all]
scores = [r['acc_mean'] * 100 for _, r in sorted_all]
colors = ['#2ecc71' if n == best_name else '#3498db' for n in names_s]
bars = ax.barh(range(len(names_s)), scores, color=colors)
ax.set_yticks(range(len(names_s)))
ax.set_yticklabels(names_s, fontsize=9)
ax.set_xlabel('Accuracy (%)')
ax.set_title('Model Karsilastirma', fontweight='bold')
for bar, s in zip(bars, scores):
    ax.text(bar.get_width()+0.3, bar.get_y()+bar.get_height()/2, f'%{s:.1f}', va='center', fontsize=8)
plt.tight_layout()
plt.savefig(os.path.join(script_dir, "model_comparison.png"), dpi=150)
plt.close()

# ============================================================
# FINAL MODEL
# ============================================================
log(f"\n{'='*65}")
log("  FINAL MODEL EGITIMI")
log(f"{'='*65}")

all_texts = [r['text'] for r in records]
aug_all_texts, aug_all_y = augment_fold_data(all_texts, y, records)

final_tfidf = TfidfVectorizer(max_features=500, ngram_range=(1, 3),
                              sublinear_tf=True, min_df=2, max_df=0.95)
X_tfidf = final_tfidf.fit_transform(aug_all_texts).toarray()
X_extra = build_extra_features(aug_all_texts)
final_scaler = StandardScaler()
X_extra = final_scaler.fit_transform(X_extra)
X_full = np.hstack([X_tfidf, X_extra])

# En iyi tekli model veya ensemble
if "Ensemble" in best_name:
    estimators = [(n, clone(model_configs[n])) for n in top3_names]
    if "Voting" in best_name:
        final_model = VotingClassifier(estimators=estimators, voting='soft')
    else:
        final_model = StackingClassifier(
            estimators=estimators,
            final_estimator=LogisticRegression(max_iter=1000, random_state=42),
            cv=3, stack_method='predict_proba'
        )
else:
    final_model = clone(model_configs[best_name])

final_model.fit(X_full, aug_all_y)

bundle = {
    'model': final_model,
    'tfidf': final_tfidf,
    'scaler': final_scaler,
    'label_encoder': le,
    'critical_keywords': CRITICAL_KW,
    'best_name': best_name,
    'accuracy': best['acc_mean'],
    'f1_weighted': best['f1_mean'],
}

bundle_path = os.path.join(script_dir, "triage_model_bundle.pkl")
joblib.dump(bundle, bundle_path)
log(f"Model kaydedildi: {bundle_path}")

log(f"\n{'='*65}")
log("  TAMAMLANDI!")
log(f"{'='*65}")
