# 🏥 Hospital Emergency Room Management System

A modern and user-friendly hospital emergency room management system. A comprehensive full-stack system consisting of Backend (Spring Boot), Frontend (React), and Mobile (Flutter) applications.

## 📋 Features

### Patient Management
- Patient registration with Turkish ID number
- Patient history viewing
- Appointment creation

### Triage System
- AI-assisted symptom analysis
- Vital signs recording
- Triage level determination (Red/Yellow/Green)
- Patient triage registration via mobile application

### Doctor Module
- Examination and diagnosis entry
- Prescription writing
- Laboratory requests
- Referral procedures

### Waiting Room Screen
- Real-time queue tracking
- Called patient display
- Automatic updates

### Dashboard
- Daily statistics
- Triage distribution
- Average waiting time

## 🚀 Installation

### Requirements

**Backend:**
- Java 17 or higher
- PostgreSQL 14 or higher
- Gradle (included with wrapper)

**Frontend:**
- Node.js 18 or higher
- npm or yarn

**Mobile:**
- Flutter SDK 3.3.0 or higher
- Dart SDK
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)

### 1. Clone the Project

```bash
git clone https://github.com/MertP06/Triage-Otomasyon-Sistemi.git
cd Triage-Otomasyon-Sistemi
```

### 2. Database Setup

Create a database in PostgreSQL:

```sql
CREATE DATABASE hospital_er;
```

**Default Connection Settings:**
- Host: `localhost:5432`
- Database: `hospital_er`
- Username: `postgres`
- Password: `1234`

> **Note:** You can change the database connection settings in `backend/er-backend/src/main/resources/application.properties`.

### 3. Backend Installation and Running

```bash
cd backend/er-backend

# For Windows
gradlew.bat bootRun

# For Linux/Mac
./gradlew bootRun
```

**Alternative (IntelliJ IDEA):**
1. Open the project in IntelliJ IDEA
2. Find `ErBackendApplication.java`
3. Right-click and select `Run 'ErBackendApplication'`

**Backend Default Port:** `8080` 
**API Base URL:** `http://localhost:8080/api`

### 4. Frontend Installation and Running

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

**Frontend Default Port:** `5173` 
**URL:** `http://localhost:5173`

> **Note:** To change the API address, create a `frontend/.env` file and add `VITE_API_BASE=http://localhost:8080/api`.

### 5. Mobile Application (Flutter) Installation and Running

#### Flutter SDK Installation

Make sure Flutter SDK is installed:

```bash
flutter --version
```

If not installed: [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)

#### Install Dependencies

```bash
cd mobil
flutter pub get
```

#### Run the Application

**For Web (Chrome):**
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api
```

**For Android Emulator:**
```bash
# First start an Android emulator, then:
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

**For iOS Simulator (macOS only):**
```bash
# First start an iOS simulator, then:
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:8080/api
```

**For Physical Device:**
- Android: Use your computer's IP address (e.g., `http://192.168.1.100:8080/api`)
- iOS: Use your computer's IP address

#### API Address Notes

| Platform | API Base URL |
|----------|-------------|
| Web (Chrome) | `http://localhost:8080/api` |
| Android Emulator | `http://10.0.2.2:8080/api` |
| iOS Simulator | `http://localhost:8080/api` |
| Physical Device | `http://[COMPUTER_IP]:8080/api` |

> **Important:** Make sure the backend is running. The mobile app will show errors if it cannot connect to the backend.

## 🔑 Login Credentials

### Web Application (Frontend)

| Role | Username | Password |
|-----|----------|----------|
| Triage Supervisor | `triyaj` | `triyaj123` |
| Doctor | `doctor` | `doctor123` |

### Mobile Application

**First Use:**
1. Open the app
2. Select "Patient Registration"
3. Enter Turkish ID Number, Name, Birth Year, and Gender
4. Create registration

**Subsequent Logins:**
1. Select "Patient Login"
2. Login with Turkish ID Number and Name

## 📡 API Endpoints

### Patients
- `GET /api/patients` - List all patients
- `POST /api/patients` - Create new patient
- `GET /api/patients/{tc}` - Get patient details by Turkish ID

### Mobile Patient Operations
- `POST /api/mobile/patient/register` - Mobile patient registration
- `POST /api/mobile/patient/login` - Mobile patient login

### Appointments
- `GET /api/appointments` - List today's appointments
- `POST /api/appointments` - Create new appointment
- `PATCH /api/appointments/{id}/status` - Update appointment status
- `GET /api/appointments/history/{tc}` - Patient history
- `GET /api/appointments/dashboard` - Dashboard statistics
- `GET /api/appointments/waiting-room` - Waiting room list
- `GET /api/appointments/mobile/queue/{tc}` - Mobile queue status query

### Triage
- `POST /api/triage` - Create triage record (Web)
- `POST /api/mobile/triage` - Mobile triage record (automatically creates appointment)
- `GET /api/triage/by-appointment/{id}` - Get triage records by appointment

### Doctor Notes
- `POST /api/doctor-notes` - Create doctor note
- `GET /api/doctor-notes/by-appointment/{id}` - Get doctor notes by appointment

## 🛠 Technologies

### Backend
- **Spring Boot 3.2** - Java framework
- **Spring Security** - Security and authentication
- **Spring Data JPA** - Database access
- **PostgreSQL** - Relational database
- **Gradle** - Build tool

### Frontend
- **React 18** - UI library
- **React Router** - Page routing
- **Vite** - Build tool and dev server
- **Axios** - HTTP client

### Mobile
- **Flutter 3.3+** - Cross-platform framework
- **Dart** - Programming language
- **Dio** - HTTP client
- **Shared Preferences** - Local data storage

## 📱 Mobile Application Details

### Features
- ✅ Patient registration/login system (Turkish ID + Name)
- ✅ Categorized symptom selection
- ✅ Symptom search feature
- ✅ Automatic triage level determination
- ✅ Real-time queue status query
- ✅ Visual urgency level display (Red/Yellow/Green)
- ✅ Modern Material Design 3 interface
- ✅ Turkish ID Number validation
- ✅ Form validations

### Project Structure

```
mobil/
├── lib/
│ ├── constants/ # Constants (colors, strings)
│ ├── models/ # Data models
│ ├── pages/ # UI pages
│ ├── services/ # API and storage services
│ └── utils/ # Helper functions
├── assets/ # JSON data files
└── pubspec.yaml # Dependencies
```

### Quick Start Scenario

1. **Start the backend:**
 ```bash
 cd backend/er-backend
 ./gradlew bootRun
 ```

2. **Start the mobile app:**
 ```bash
 cd mobil
 flutter pub get
 flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api
 ```

3. **Test flow:**
 - Create patient registration (Turkish ID, Name, Birth Year, Gender)
 - Select symptoms and create triage record
 - View urgency level and queue number
 - Update queue status

## 📁 Project Structure

```
hospital_er/
├── backend/
│ └── er-backend/ # Spring Boot backend
├── frontend/ # React frontend
├── mobil/ # Flutter mobile application
└── dataset/ # Sample data files
```

## 🧪 Testing

### Backend Tests
```bash
cd backend/er-backend
./gradlew test
```

### Frontend Tests
```bash
cd frontend
npm test
```

### Flutter Tests
```bash
cd mobil
flutter test
```

## 🐛 Troubleshooting

### Backend won't start
- Make sure PostgreSQL service is running
- Check database connection settings
- Ensure port 8080 is available

### Frontend can't connect to API
- Make sure backend is running
- Check `VITE_API_BASE` value in `.env` file
- Check CORS settings

### Flutter app won't run
- Make sure Flutter SDK is installed: `flutter doctor`
- Install dependencies: `flutter pub get`
- Make sure API address is correct (varies by platform)
- Make sure backend is running

### Android Emulator API connection issue
- Use `10.0.2.2` address for Android emulator
- Make sure emulator has internet connection

## 🤝 Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 👥 Developers

This project was developed for educational purposes.

---

**Note:** This system is for demonstration purposes and should not be used for real medical decisions.
