# IPlay - IP Rights Learning Platform 🎮

> **A gamified, free-to-use mobile app for learning Intellectual Property Rights in India**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Current Status**: 55% Complete (59/108 tasks) | Core Infrastructure: 100% Ready ✅

---

## 📖 Overview

IPlay is a comprehensive educational platform designed to teach students about Intellectual Property Rights through:
- **6 IPR Realms**: Copyright, Trademark, Patent, Industrial Design, GI, Trade Secrets
- **Interactive Games**: 7 engaging games for hands-on learning
- **Gamification**: XP system, badges, streaks, certificates
- **School Integration**: Classroom management, assignments, leaderboards
- **Daily Challenges**: Fresh content every day

**Target Audience**: Students (grades 8-12) across India

---

## ✨ Features

### 🎓 Learning System
- ✅ 6 IPR realms with 42 total levels (Copyright realm complete)
- ✅ Progressive difficulty (Easy → Expert)
- ✅ Interactive quizzes after each level
- ✅ Real-world examples and case studies
- ⏳ 5 more realms in development

### 🏆 Gamification
- ✅ XP system with difficulty tiers (50-200 XP per level)
- ✅ 35 badges across 5 categories
- ✅ Daily XP cap (1000 XP) to prevent grinding
- ✅ Streak system with 48-hour grace period
- ✅ Replay XP reduction (100% → 25% → 10% → 0%)
- ✅ Multiple bonus types (first login, streak milestones, realm completion)

### 🎮 Games
- ⏳ **IPR Quiz Master** (current): Timed multiple-choice
- ⏳ **Match the IPR**: Memory card matching
- ⏳ 5 more games in development

### 🏫 School System
- ✅ Principal/Teacher/Student hierarchy
- ✅ School creation with unique codes
- ✅ Classroom management
- ✅ Assignment creation, submission, grading
- ✅ Join request approval workflow
- ✅ Multi-scope leaderboards (classroom/school/state/national)

### 📊 Progress Tracking
- ✅ Individual progress for each level
- ✅ Realm completion tracking
- ✅ Accuracy and attempt count
- ✅ Time spent analytics
- ✅ Certificate generation on realm completion

### 🎯 Daily Challenges
- ✅ Auto-generated 5-question challenges (12:01 AM IST)
- ✅ 50 XP reward
- ✅ One attempt per day
- ✅ Leaderboard for challenge scores

### 🏅 Certificates
- ✅ PDF generation with QR codes
- ✅ Unique certificate numbers
- ✅ Download and share functionality
- ✅ Auto-issued on realm completion

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** 3.0+ - Cross-platform mobile framework
- **Provider** - State management
- **Cloud Firestore** - Real-time database sync

### Backend
- **Firebase Authentication** - Email + Google Sign-In
- **Cloud Firestore** - NoSQL database (15 collections)
- **Cloud Functions** - Serverless backend (9 functions)
- **Firebase Storage** - File storage (avatars, certificates, attachments)
- **Firebase Hosting** - Static content hosting

### Key Packages
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  google_sign_in: ^6.1.6
  provider: ^6.1.1
  intl: ^0.19.0
  sqflite: ^2.3.0  # Offline mode
```

---

## 📁 Project Structure

```
iplay/
├── lib/
│   ├── core/
│   │   ├── models/          # 8 data models
│   │   ├── services/        # 9 services
│   │   ├── constants/       # App-wide constants
│   │   ├── data/           # Static data (realms, badges)
│   │   ├── providers/      # State management
│   │   └── theme/          # App theme
│   ├── screens/            # 50+ screens
│   │   ├── auth/           # Authentication flow
│   │   ├── learn/          # Learning content
│   │   ├── games/          # IPR games
│   │   ├── classroom/      # Classroom management
│   │   ├── school/         # School management
│   │   ├── assignment/     # Assignment system
│   │   └── ...
│   ├── widgets/            # Reusable components
│   └── main.dart
├── functions/              # Cloud Functions
│   ├── index.js           # 9 functions
│   └── package.json
├── assets/                # Images, icons
├── docs/                  # Detailed documentation
├── firestore.rules        # Security rules
├── firestore.indexes.json # Database indexes
└── firebase.json          # Firebase config
```

---

## 🚀 Getting Started

### Prerequisites
```bash
node --version  # v18.x or higher
npm --version   # v8.x or higher
flutter --version  # v3.0 or higher
```

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/iplay.git
cd iplay
```

2. **Install Flutter dependencies**
```bash
flutter pub get
```

3. **Set up Firebase Configuration** ⚠️ REQUIRED

   The following files are excluded from version control for security:
   - `android/app/google-services.json`
   - `lib/firebase_options.dart`
   - `android/local.properties`
   
   **To set up Firebase:**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Authentication (Email/Password + Google)
   - Create Firestore database (follow `firestore.rules` for security)
   - Enable Firebase Storage
   - Download `google-services.json` to `android/app/`
   - Run `flutterfire configure` to generate `firebase_options.dart`
   - Update `android/local.properties` with your local Android SDK path

4. **Install Cloud Functions dependencies** (optional)
```bash
cd functions
npm install
cd ..
```

5. **Run the app**
```bash
flutter run
```

### First-Time Setup

**Populate badges database** (run once):
```dart
import 'package:iplay/core/utils/populate_badges.dart';

// In a temporary admin screen:
final populator = BadgePopulator();
await populator.populateBadges();
await populator.verifyBadges();
```

---

## 🔥 Firebase Deployment

### Deploy everything
```bash
firebase deploy
```

### Deploy specific components
```bash
firebase deploy --only functions
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
firebase deploy --only storage
```

### View logs
```bash
firebase functions:log
firebase functions:log --only dailyLeaderboardUpdate
```

---

## 📊 Database Schema

### Collections (15 total)

| Collection | Documents | Purpose |
|------------|-----------|---------|
| `/users` | User profiles | Authentication & progress |
| `/schools` | School entities | Principal management |
| `/classrooms` | Classroom groups | Teacher-student hierarchy |
| `/announcements` | Class announcements | Teacher communication |
| `/progress` | Learning progress | Top-level with composite IDs |
| `/badges` | Badge definitions | 35 badges (seeded) |
| `/join_requests` | Classroom requests | Approval workflow |
| `/assignments` | Teacher assignments | Homework system |
| `/assignment_submissions` | Student work | Submission + grading |
| `/certificates` | Achievements | PDF certificates |
| `/daily_challenges` | Daily quizzes | 5Q challenges |
| `/daily_challenge_attempts` | Challenge results | One per user/day |
| `/reports` | Content moderation | Report system |
| `/feedback` | User feedback | Feature requests |
| `/leaderboard_cache` | Rankings | Daily aggregated |

---

## ☁️ Cloud Functions

### Scheduled Functions
- **`dailyLeaderboardUpdate`** - 2:00 AM IST
  - Aggregates all leaderboards (national/state/school/classroom)
  - Top 100 rankings
  - Solo vs classroom learners

- **`dailyChallengeGeneration`** - 12:01 AM IST
  - Creates daily 5-question challenge
  - 50 XP reward
  - Random from question bank

- **`weeklyCleanup`** - Sunday 3:00 AM IST
  - Deletes old join requests (30+ days)
  - Removes expired announcements

### Triggered Functions
- **`generateCertificate`** - On realm completion
  - PDF generation with QRCode
  - Upload to Storage
  - Unique certificate numbers

- **`onUserDeleted`** - On user deletion
  - Cleanup all user data
  - Remove from classrooms

- **`onClassroomDeleted`** - On classroom deletion
  - Update student records
  - Delete related data

### Callable Functions
- **`transferSchoolOwnership`** - Principal transfer
- **`banUser`** - Admin-only user ban

---

## 🎯 XP System Details

### Difficulty Tiers
```
Easy:   50 XP   (Introductory concepts)
Medium: 100 XP  (Standard learning)
Hard:   150 XP  (Complex topics)
Expert: 200 XP  (Advanced challenges)
```

### Replay XP Reduction
```
1st attempt: 100% XP
2nd attempt: 25% XP
3rd attempt: 10% XP
4th+ attempt: 0% XP
```

### Daily XP Cap
- Maximum: 1000 XP per day
- Prevents grinding
- Warning shown at 800 XP
- Blocked at 1000 XP

### Bonuses
- First login of day: +10 XP
- 7-day streak milestone: +100 XP
- Realm completion: +300 XP
- Badge unlock: +10 to +500 XP (varies by badge)

---

## 🏅 Badge System

### Categories (35 total)

**Milestone Badges (10)**
- First Step, Level Explorer, Level Veteran
- XP Collector, XP Master, XP Legend, XP Titan
- Perfect Start, Perfectionist, Quiz Genius

**Streak Badges (6)**
- 3, 7, 14, 30, 60, 100 days

**Mastery Badges (7)**
- Copyright Master, Trademark Master, Patent Master
- Design Master, GI Master, Secrets Master
- IPR Champion (all realms)

**Social Badges (6)**
- Social Learner, Class Champion, School Star
- State Leader, Assignment Ace, Helpful Student

**Special Badges (6)**
- Early Adopter, Speedrunner, Night Owl
- Weekend Warrior, Daily Champion, Game Master

---

## 🔒 Security

### Firestore Rules
- Row-level security on all collections
- Users can only access their own data
- Teachers manage their classrooms
- Principals manage their schools
- Cloud Functions have admin access

### Storage Rules
- Profile images: 5 MB limit, images only
- Attachments: 10 MB limit
- Certificates: Functions write-only

### Authentication
- Email verification required
- Password reset enabled
- Google Sign-In configured
- No password storage in app

---

## 📈 Free Tier Sustainability

### Firebase Limits (Free Tier)
✅ **Firestore**: 50K reads/day, 20K writes/day, 1 GB storage
✅ **Functions**: 125K invocations/month, 400K GB-seconds
✅ **Storage**: 5 GB total, 1 GB downloads/day
✅ **Authentication**: Unlimited

### Estimated Usage (100 students)
- Reads: ~5K/day (well within limit)
- Writes: ~2K/day (10% of limit)
- Function invocations: ~90/month scheduled + ~500/month user actions
- **Conclusion**: Free tier sufficient for 500+ students

---

## 🧪 Testing

### Manual Testing Checklist

#### Authentication Flow
- [ ] Sign up with email
- [ ] Email verification
- [ ] Sign in with Google
- [ ] Password reset
- [ ] Role selection

#### Learning Flow
- [ ] Browse realms
- [ ] Complete a level
- [ ] Take a quiz
- [ ] Earn XP and badges
- [ ] View progress

#### School System
- [ ] Principal creates school
- [ ] Teacher creates classroom
- [ ] Student joins classroom
- [ ] Teacher approves join request
- [ ] View classroom leaderboard

#### Assignment System
- [ ] Teacher creates assignment
- [ ] Student submits work
- [ ] Teacher grades submission
- [ ] Student views feedback

#### Daily Challenge
- [ ] Complete today's challenge
- [ ] Verify one-attempt limit
- [ ] Check XP reward

---

## 📝 Documentation

Comprehensive docs in `/docs/` folder:
- `01_EXECUTIVE_SUMMARY.md` - Project overview
- `02_DATABASE_SCHEMA.md` - Complete schema
- `03_USER_FLOWS.md` - 25+ user flows
- `04_UI_SPECIFICATIONS.md` - Design system
- `05_GAMIFICATION_SYSTEM.md` - XP, badges, certificates
- `06_SECURITY_FUNCTIONS.md` - Rules and functions
- `07_IMPLEMENTATION_GUIDE.md` - Development roadmap

Additional files:
- `IMPLEMENTATION_PROGRESS.md` - Detailed task tracker
- `DEPLOYMENT_GUIDE.md` - Deployment instructions
- `LEARNING_CONTENT_STRUCTURE.md` - Content guidelines

---

## 🎨 Design System

### Colors
```dart
Primary: #4A90E2    // Blue
Success: #4CAF50    // Green
Warning: #FFA726    // Orange
Error: #EF5350      // Red
Background: #F5F7FA // Light Gray
```

### Typography
- Headers: Poppins (Bold)
- Body: Inter (Regular)
- Monospace: Fira Code

### Components
- Cards with 12px border radius
- 16px spacing unit
- Elevated buttons with shadows
- Progress bars with animations

---

## 🗺️ Roadmap

### Phase 1: Core Infrastructure ✅ (Current)
- [x] Authentication system
- [x] Database schema
- [x] XP & badge system
- [x] Cloud Functions
- [x] School/classroom management
- [x] Assignment system

### Phase 2: Content Creation 🔄 (In Progress)
- [x] Copyright Realm (complete)
- [ ] Trademark Realm
- [ ] Patent Realm
- [ ] Industrial Design Realm
- [ ] GI Realm
- [ ] Trade Secrets Realm

### Phase 3: Games 🎮 (Upcoming)
- [x] IPR Quiz Master
- [x] Match the IPR
- [ ] Spot the Original
- [ ] IP Defender
- [ ] GI Mapper
- [ ] Patent Detective
- [ ] Innovation Lab

### Phase 4: Polish ✨ (Future)
- [ ] Offline mode
- [ ] Push notifications
- [ ] Advanced analytics
- [ ] Animations & transitions
- [ ] App Check security
- [ ] Firebase Hosting for content

---

## 🤝 Contributing

We welcome contributions! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write/update tests
5. Submit a pull request

### Development Guidelines
- Follow Flutter best practices
- Use Provider for state management
- Write clean, documented code
- Test on both Android and iOS

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

- **Project Lead**: [Your Name]
- **Backend**: Firebase
- **Frontend**: Flutter
- **Design**: Material Design 3

---

## 📧 Contact

- **Email**: support@iplay.app
- **Website**: https://iplay.app
- **Issues**: [GitHub Issues](https://github.com/yourusername/iplay/issues)

---

## 🙏 Acknowledgments

- Firebase team for excellent BaaS
- Flutter team for cross-platform framework
- Indian IP law resources
- All contributors and testers

---

## 📊 Current Status

**Overall Progress**: 59/108 tasks (55%)

| Category | Status |
|----------|--------|
| 🔴 Critical Fixes | 7/7 (100%) ✅ |
| 📦 Models | 7/7 (100%) ✅ |
| 🔒 Security Rules | 8/8 (100%) ✅ |
| ⚙️ Services | 8/8 (100%) ✅ |
| 💎 XP System | 6/6 (100%) ✅ |
| 🏅 Badges | 4/4 (100%) ✅ |
| ☁️ Cloud Functions | 9/12 (75%) 🟡 |
| 📱 Screens | 9/13 (69%) 🟡 |
| 🔥 Firebase Config | 1/4 (25%) 🟡 |
| 📚 Content | 0/5 (0%) ⏳ |
| 🎮 Games | 0/5 (0%) ⏳ |

**Ready for deployment** ✅

---

<p align="center">
  Made with ❤️ for Indian students learning IP Rights
</p>
