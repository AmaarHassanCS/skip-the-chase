# SkipTheChase Dating App

A modern dating app that allows users to check in to venues and find dates around them.

## Installation
- flutter clean
- flutter pub get
- flutter run
- flutter devices



## To complete the implementation:

- Create a Supabase project and run the SQL script in lib/utils/supabase_schema.sql
- Update the Supabase URL and anon key in lib/main.dart
- Set up storage buckets for profile images
- Run the app with flutter run


## Features

- **Authentication**: Email and Google sign-in
- **Location-based Check-ins**: Users can check in to venues verified by GPS
- **Multiple Check-ins**: Users can check in to multiple nearby locations
- **Timed Check-ins**: Check-ins with configurable durations
- **Swipe Interface**: Traditional swipe left/right functionality
- **Real-time Chat**: Messaging between matched users
- **Auto-expiring Chats**: Messages are automatically deleted after 2-3 days
- **Video Calling**: (Advanced feature) Users can call each other
- **Profile Management**: Users can customize their profiles
- **Safety Features**: Block and report functionality

## Tech Stack

- **Frontend**: Flutter for cross-platform mobile development
- **Backend**: Supabase for authentication, database, and storage
- **Location Services**: Geolocator package for GPS functionality
- **State Management**: Provider pattern
- **Real-time Features**: Supabase real-time subscriptions

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Supabase account
- Android Studio / Xcode for mobile development

### Setup

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/skip_the_chase.git
   cd skip_the_chase
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Create a Supabase project and set up the database:
   - Create a new project in Supabase
   - Run the SQL script in `lib/utils/supabase_schema.sql` in the Supabase SQL editor
   - Create storage buckets for profile images

4. Configure environment variables:
   - Update the Supabase URL and anon key in `lib/main.dart`

5. Run the app:
   ```
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── models/                    # Data models
├── providers/                 # State management
├── screens/                   # UI screens
│   ├── auth/                  # Authentication screens
│   ├── home_screen.dart       # Main screen with bottom navigation
│   ├── discover_screen.dart   # Swipe interface
│   ├── check_in_screen.dart   # Venue check-in
│   ├── matches_screen.dart    # Matches and messages
│   ├── chat_screen.dart       # Individual chat
│   └── profile_screen.dart    # User profile
├── services/                  # Business logic
├── utils/                     # Utilities and helpers
└── widgets/                   # Reusable UI components
```

## Database Schema

The app uses the following main tables in Supabase:
- `profiles`: User profiles
- `venues`: Available check-in locations
- `check_ins`: User venue check-ins
- `swipes`: User swipe actions
- `matches`: Mutual matches
- `messages`: Chat messages
- `blocks`: Blocked users
- `reports`: User reports

## Future Enhancements

- Implement video calling using WebRTC or Agora
- Add advanced matching algorithms
- Implement push notifications
- Add verification system for users
- Expand safety features