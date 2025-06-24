# Skip The Chase - Dating App

A modern Flutter dating app that facilitates both venue-based in-person meetings and traditional matching through swiping.

## Features

- **Dual Dating Modes**: Traditional swiping and venue-based check-ins
- **Real-time Location**: Find people at the same venues
- **Secure Authentication**: Email and Google sign-in via Supabase
- **Match System**: Mutual likes create matches with 3-day expiration
- **Chat System**: Real-time messaging between matches
- **Profile Management**: Rich user profiles with photos and interests
- **Safety Features**: Block and report functionality

## Tech Stack

- **Frontend**: Flutter (iOS & Android)
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **State Management**: Provider
- **Navigation**: GoRouter
- **Location Services**: Geolocator
- **Image Handling**: Image Picker + Cached Network Image

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / Xcode for mobile development
- Supabase account

### 2. Supabase Setup

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Run the SQL schema from `database_schema.sql` in your Supabase SQL editor
3. Run the additional functions from `additional_functions.sql`
4. Enable Row Level Security on all tables
5. Configure authentication providers (Email, Google)

### 3. Flutter Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Update Supabase credentials in `lib/main.dart`:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

4. For Google Sign-In, configure:
   - Android: Add `google-services.json` to `android/app/`
   - iOS: Add `GoogleService-Info.plist` to `ios/Runner/`

### 4. Permissions

The app requires the following permissions:
- Location (for venue check-ins)
- Camera (for profile photos)
- Storage (for photo uploads)

### 5. Database Schema

The app uses a scalable PostgreSQL schema designed for millions of users:

- **profiles**: User profile information
- **venues**: Location data for check-ins
- **check_ins**: User location check-ins with duration
- **swipes**: Left/right swipe actions
- **matches**: Mutual likes with expiration
- **messages**: Chat messages between matches
- **blocks/reports**: Safety and moderation features

### 6. Running the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Specific platform
flutter run -d android
flutter run -d ios
```

## App Architecture

```
lib/
├── config/          # Configuration files
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
│   ├── auth/        # Authentication screens
│   ├── home/        # Main home screen
│   ├── swipe/       # Swipe functionality
│   ├── matches/     # Match management
│   ├── chat/        # Messaging
│   ├── profile/     # User profile
│   └── checkin/     # Venue check-ins
├── services/        # API services
└── widgets/         # Reusable components
```

## Key Features Implementation

### Venue-Based Dating
- GPS verification within 100m radius
- Real-time user discovery at venues
- Timed check-ins with duration selection

### Traditional Swiping
- Card-based UI with smooth animations
- Mutual matching system
- Preference-based filtering

### Safety & Security
- Row Level Security (RLS) policies
- User blocking and reporting
- Match expiration (3 days)
- Chat message cleanup

### Scalability Features
- Optimized database indexes
- Geographic queries with PostGIS
- Efficient pagination
- Background cleanup functions

## Database Performance

The schema is optimized for scale:
- **1M+ users**: Indexed user profiles
- **100M+ swipes**: Partitioned by date
- **50M+ matches**: Efficient mutual matching
- **500M+ messages**: Optimized chat queries
- **10M+ check-ins**: Geographic indexing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
1. Check the documentation
2. Search existing issues
3. Create a new issue with detailed information

---

**Note**: Remember to replace placeholder values with your actual Supabase credentials before running the app.