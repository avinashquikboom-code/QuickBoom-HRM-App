# QuickBoom HRM Mobile App

A comprehensive HR Management System mobile application built with Flutter, supporting both employees and HR personnel.

## Features

### Employee Features
- **Dashboard**: View daily stats, attendance summary, and notifications
- **Attendance**: Check-in/check-out with geofencing validation
- **Leave Management**: Apply for leave and view leave balances
- **Expenses**: Submit expense claims with receipts
- **Shifts**: View assigned shift schedules
- **Profile**: Manage personal information and avatar
- **Notifications**: View and manage push notifications
- **Change Password**: Update account password
- **Forgot Password**: Reset password via email

### HR Features
- **HR Dashboard**: View HR-specific analytics and stats
- **Employee Management**: View and manage team members
- **Leave Approval**: Approve/reject leave requests
- **Expense Approval**: Review and approve expense claims
- **Payroll**: View payroll runs and salary information
- **Reports**: Access HR reports and analytics

### General Features
- **Theme Support**: Light and dark mode with persistence
- **Offline Support**: Local data caching
- **Push Notifications**: Firebase Cloud Messaging integration
- **Location Tracking**: GPS-based attendance verification
- **Responsive Design**: Optimized for various screen sizes

## Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **State Management**: Riverpod
- **API Client**: http package
- **Local Storage**: shared_preferences
- **Icons**: RemixIcon
- **Animations**: flutter_animate
- **Notifications**: Firebase Cloud Messaging
- **Geolocation**: geolocator, geocoding

## Prerequisites

- Flutter SDK >= 3.0.x
- Dart SDK >= 3.0.x
- Android Studio / Xcode
- Android SDK / iOS SDK

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd quickboom_hrm
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Add `google-services.json` for Android
   - Add `GoogleService-Info.plist` for iOS
   - Update `firebase_options.dart` with your Firebase configuration

4. Update API URL:
   - Edit `lib/core/constants/app_url.dart`
   - Set the correct `baseUrl` for your backend API

## Running the Application

### Android
```bash
flutter run
```

### iOS
```bash
flutter run
```

### Web
```bash
flutter run -d chrome
```

## Project Structure

```
lib/
├── core/
│   ├── constants/       # App constants (colors, theme, URLs)
│   ├── services/        # Services (API, notifications, theme)
│   └── utils/           # Utility functions
├── viewmodels/          # Riverpod providers/state management
├── views/
│   ├── auth/           # Authentication screens
│   ├── employee/       # Employee-specific screens
│   ├── hr/             # HR-specific screens
│   └── widgets/        # Reusable widgets
└── main.dart           # Application entry point
```

## Configuration

### API Configuration
Edit `lib/core/constants/app_url.dart` to configure your backend API:
```dart
static const String baseUrl = 'https://your-api-url.com';
```

### Firebase Configuration
Update `firebase_options.dart` with your Firebase project configuration.

## Available Scripts

- `flutter run` - Run the app
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build web` - Build web app
- `flutter clean` - Clean build artifacts
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

## Test Credentials

The app includes test credentials for development (printed in console on startup):

**Employee:**
- Email: employee@hrm.com
- Password: employee123

**HR:**
- Email: hr@hrm.com
- Password: 123456

**Admin:**
- Email: admin@hr.com
- Password: 123456

## Permissions

### Android
Add the following permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS
Add the following permissions to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to verify attendance</string>
<key>NSCameraUsageDescription</key>
<string>We need camera access for profile photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access for profile photos</string>
```

## Theme Persistence

The app supports light and dark themes. Theme preference is saved using `shared_preferences` and automatically applied on app restart.

## Troubleshooting

### Build Issues
- Run `flutter clean` and `flutter pub get`
- Ensure Flutter SDK is up to date: `flutter upgrade`

### Firebase Issues
- Verify Firebase configuration in `firebase_options.dart`
- Ensure google-services.json / GoogleService-Info.plist are correctly placed

### Location Issues
- Ensure location permissions are granted
- Check that GPS is enabled on the device

## License

MIT

## Support

For support, email support@quickboom.com
