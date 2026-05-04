# -*- coding: utf-8 -*-
"""Acil Servis Triaj - Inference (Tahmin) Dosyasi
triage_model_bundle.pkl (Text-First Model) kullanarak tahmin yapar."""
import sys, json, os, joblib, warnings
import numpy as np

warnings.filterwarnings('ignore')

CRITICAL_KW = [
    'nefes', 'bilinc', 'kanama', 'bayil', 'felc', 'kalp', 'gogus',
    'kaza', 'kirik', 'zehir', 'intihar', 'nobet', 'ates', 'siddetli',
    'ani', 'acil', 'sok', 'travma', 'koma', 'yarali', 'agri',
    'kusma', 'ishal', 'iltihap', 'enfeksiyon', 'sanci', 'krampi'
]

# TIBBI GUVENLIK AGI KELIMELERI (Bunlar varsa asla YESIL olamaz, KIRMIZI olma ihtimali zorlanir)
FATAL_KEYWORDS = [
    'kalp krizi', 'koma', 'nefes alam', 'bilinc kapali', 'silah', 'bicak',
    'intihar', 'baygin', 'nabiz yok', 'kalbi dur', 'solunum yok', 'felc',
    'gogus agrisi', 'gogsum sikisiyor'
]

def normalize_tr(text):
    text = text.strip().lower()
    tr_map = str.maketrans('çğıöşüÇĞİÖŞÜ', 'cgiosuCGIOSU')
    return text.translate(tr_map)

def build_extra_features(text):
    """Ek sayisal ozellikler (Model 3'teki yapinin aynisi)"""
    nt = normalize_tr(text)
    words = text.split()
    kw_count = sum(1 for kw in CRITICAL_KW if kw in nt)
    return [
        len(text), len(words),
        np.mean([len(w) for w in words]) if words else 0,
        kw_count, kw_count / len(CRITICAL_KW),
        text.count('!') + text.count('?'),
        sum(1 for c in text if c.isupper()) / max(len(text), 1),
    ]

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Semptom/Metin parametresi eksik"}))
        sys.exit(1)

    input_symptoms_csv = sys.argv[1]
    input_text = sys.argv[2] if len(sys.argv) > 2 else ""
    input_symptoms = [s.strip().lower() for s in input_symptoms_csv.split(',')]
    
    # Model 3'teki gibi symptoms ve input_text'i birlestiriyoruz
    combined_text = input_text + " " + " ".join(input_symptoms)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    bundle_path = os.path.join(script_dir, "triage_model_bundle.pkl")

    try:
        bundle = joblib.load(bundle_path)
    except Exception as e:
        print(json.dumps({"error": f"Model yuklenemedi: {e}"}))
        sys.exit(1)

    model = bundle['model']
    tfidf = bundle['tfidf']
    scaler = bundle['scaler']
    le = bundle['label_encoder']

    # 1. TF-IDF vektorizasyonu
    X_tfidf = tfidf.transform([combined_text]).toarray()
    
    # 2. Istatistiksel (Extra) feature'lar
    extra_features = np.array([build_extra_features(combined_text)])
    X_extra = scaler.transform(extra_features)
    
    # 3. Birlestirme
    X_full = np.hstack([X_tfidf, X_extra])

    try:
        probs = model.predict_proba(X_full)[0]
        classes = list(le.classes_)
        
        # Sınıfların indekslerini bul (Buyuk/kucuk harf hatasina karsi guvenli arama)
        kirmizi_idx = next(i for i, c in enumerate(classes) if c.upper() == 'KIRMIZI')
        
        kirmizi_prob = probs[kirmizi_idx]
        
        # Hastanin metninde gecen kritik ve olumcul durumlari bulalim
        nt = normalize_tr(combined_text)
        matched_kws = [kw for kw in CRITICAL_KW if kw in nt]
        matched_fatals = [fw for fw in FATAL_KEYWORDS if normalize_tr(fw) in nt]
        kw_text = f"Saptanan riskler: {', '.join(matched_kws)}" if matched_kws else "Rutin vaka gorunumu"

        # ==========================================
        # TIBBI GUVENLIK AGI (MEDICAL SAFETY NET)
        # ==========================================
        is_fatal = len(matched_fatals) > 0
        
        # KURAL 1: Kirmizi ihtimali %20'den buyukse, riske atma, Kirmizi ver!
        if kirmizi_prob >= 0.20:
            pred_idx = kirmizi_idx
            color = "KIRMIZI"
            confidence = int(kirmizi_prob * 100)
            explanation = f"AI TIBBI GUVENLIK AGI: Kirmizi Kod (%{confidence}) atandi. Model %20+ risk algiladigi icin hasta riske atilmadi. {kw_text}."
            
        # KURAL 2: Ölümcül kelime varsa (ve kirmizi prob %20'yi gecmediyse bile) zorla Kirmizi ver!
        elif is_fatal:
            pred_idx = kirmizi_idx
            color = "KIRMIZI"
            confidence = 99
            explanation = f"AI TIBBI GUVENLIK AGI: Kirmizi Kod atandi. Olumcul bulgu tespit edildi ({', '.join(matched_fatals)}). {kw_text}."
            
        # KURAL 3: Normal secim (Sari veya Yesil)
        else:
            pred_idx = np.argmax(probs)
            color = classes[pred_idx].upper()
            confidence = int(probs[pred_idx] * 100)
            explanation = f"AI Algoritmasi {color} Kodu (%{confidence}) olarak siniflandirdi. {kw_text}."

        print(json.dumps({
            "color": color,
            "confidence": confidence,
            "explanation": explanation
        }))
    except Exception as e:
        print(json.dumps({"error": f"Tahmin hatasi: {e}"}))
        sys.exit(1)

if __name__ == "__main__":
    main()
