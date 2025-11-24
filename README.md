# Hospital ER Management System

Hastane acil servis yönetim sistemi - Backend (Spring Boot) ve Frontend (React) ile geliştirilmiş tam kapsamlı bir uygulama.

## 🏗️ Proje Yapısı

```
hospital_er/
├── backend/              # Spring Boot Backend
│   └── er-backend/
├── frontend/             # React + Vite Frontend
└── dataset/              # Tıbbi veri seti (medical_data.json)
```

## 🚀 Hızlı Başlangıç

### Gereksinimler

- **Backend:**
  - Java 17+
  - PostgreSQL 12+
  - Gradle 7+

- **Frontend:**
  - Node.js 18+
  - npm veya yarn

### Backend Kurulumu

1. PostgreSQL veritabanını oluşturun:
```sql
CREATE DATABASE hospital_er;
CREATE USER er_user WITH PASSWORD 'er_pass';
GRANT ALL PRIVILEGES ON DATABASE hospital_er TO er_user;
```

2. Backend dizinine gidin:
```bash
cd backend/er-backend
```

3. Uygulamayı çalıştırın:
```bash
./gradlew bootRun
# Windows için:
gradlew.bat bootRun
```

Backend `http://localhost:8080` adresinde çalışacaktır.

### Frontend Kurulumu

1. Frontend dizinine gidin:
```bash
cd frontend
```

2. Bağımlılıkları yükleyin:
```bash
npm install
```

3. Environment değişkenlerini ayarlayın:
`.env` dosyası oluşturun (veya `.env.example` dosyasını kopyalayın):
```env
VITE_API_BASE_URL=http://localhost:8080
```

4. Uygulamayı çalıştırın:
```bash
npm run dev
```

Frontend `http://localhost:5173` adresinde çalışacaktır.

## 🔐 Giriş Bilgileri

- **Hemşire (NURSE):**
  - Kullanıcı adı: `nurse`
  - Şifre: `nurse123`

- **Doktor (DOCTOR):**
  - Kullanıcı adı: `doctor`
  - Şifre: `doctor123`

## 📋 Özellikler

### Backend Özellikleri

- ✅ RESTful API (Spring Boot 3.1.0)
- ✅ JPA/Hibernate ile veritabanı yönetimi
- ✅ Spring Security ile kimlik doğrulama (BCrypt şifreleme)
- ✅ Global CORS yapılandırması
- ✅ Standart API response formatı
- ✅ Kapsamlı exception handling
- ✅ Logging (SLF4J/Logback)
- ✅ Validation (@Valid annotations)
- ✅ Transaction yönetimi

### Frontend Özellikleri

- ✅ React 19 + Vite
- ✅ React Router ile sayfa yönlendirme
- ✅ Authentication context
- ✅ Protected routes
- ✅ Environment variables desteği
- ✅ Gelişmiş error handling
- ✅ Optimize edilmiş build yapılandırması

### Modüller

1. **Hasta Yönetimi (Patient)**
   - Hasta kaydı oluşturma
   - Hasta listeleme ve arama
   - Hasta bilgilerini güncelleme

2. **Randevu Yönetimi (Appointment)**
   - Randevu oluşturma
   - Randevu durumu takibi
   - Sıra numarası yönetimi
   - TC ile randevu sorgulama

3. **Triage (Ön Değerlendirme)**
   - Semptom seçimi
   - Yaşamsal bulgular kaydı
   - Triage seviyesi belirleme
   - AI destekli öneriler

4. **Doktor Notları (Doctor Notes)**
   - Tanı kaydı
   - Tedavi planı
   - Randevu tamamlama

5. **Tıbbi Veri (Medical Data)**
   - Semptom arama
   - Aciliyet seviyesi önerileri
   - Tıbbi veri seti entegrasyonu

## 🛠️ Teknolojiler

### Backend
- Spring Boot 3.1.0
- Spring Security
- Spring Data JPA
- PostgreSQL
- Jackson (JSON)
- SLF4J/Logback

### Frontend
- React 19
- Vite 7
- React Router DOM 7
- Modern ES6+ JavaScript

## 📁 API Endpoints

### Hasta Endpoints
- `POST /api/patients` - Yeni hasta oluştur
- `GET /api/patients` - Tüm hastaları listele
- `GET /api/patients/{id}` - Hasta detayı
- `PUT /api/patients/{id}` - Hasta güncelle
- `PATCH /api/patients/{id}` - Kısmi güncelleme
- `DELETE /api/patients/{id}` - Hasta sil

### Randevu Endpoints
- `POST /api/appointments` - Randevu oluştur
- `GET /api/appointments/today` - Bugünkü randevular
- `GET /api/appointments/status/{tc}` - TC ile randevu sorgula
- `GET /api/appointments/{id}/detail` - Randevu detayı
- `PATCH /api/appointments/{id}/status` - Durum güncelle
- `DELETE /api/appointments/{id}` - Randevu sil

### Triage Endpoints
- `POST /api/triage` - Triage kaydı oluştur
- `GET /api/triage/by-appointment/{appointmentId}` - Randevu triage kayıtları

### Doktor Notları
- `POST /api/doctor-notes` - Doktor notu oluştur
- `POST /api/doctor-notes/complete` - Not oluştur ve randevuyu tamamla
- `GET /api/doctor-notes/by-appointment/{appointmentId}` - Randevu notları

### Tıbbi Veri
- `GET /api/medical/search?symptoms=...` - Semptom arama
- `GET /api/medical/symptoms` - Tüm semptomlar
- `GET /api/medical` - Tüm tıbbi veri

## 🔧 Yapılandırma

### Backend Yapılandırması

`backend/er-backend/src/main/resources/application.yml` dosyasında:

```yaml
server:
  port: 8080

spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/hospital_er
    username: er_user
    password: er_pass
```

### Frontend Yapılandırması

`frontend/.env` dosyasında:

```env
VITE_API_BASE_URL=http://localhost:8080
```

## 🧪 Test

### Backend Test
```bash
cd backend/er-backend
./gradlew test
```

### Frontend Build
```bash
cd frontend
npm run build
```

## 📝 Notlar

- Production ortamında BCrypt şifreleme kullanılmaktadır
- CORS yapılandırması sadece belirli origin'lere izin verir
- Tüm API yanıtları standart `ApiResponse` formatında döner
- Logging tüm önemli işlemler için aktif

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📄 Lisans

Bu proje eğitim amaçlı geliştirilmiştir.

## 👨‍💻 Geliştirici

Proje optimizasyonları ve iyileştirmeler yapılmıştır:
- ✅ Global CORS yapılandırması
- ✅ BCrypt şifreleme
- ✅ Standart API response formatı
- ✅ Gelişmiş error handling
- ✅ Logging entegrasyonu
- ✅ Validation iyileştirmeleri
- ✅ Frontend optimizasyonları
- ✅ Build optimizasyonları

