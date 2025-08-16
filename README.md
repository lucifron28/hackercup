# JeepGo - Real-Time Jeepney Tracking System

# Install APK
[Click Here to Download](https://github.com/lucifron28/hackercup/raw/refs/heads/main/build/app/outputs/flutter-apk/app-release.apk)

A comprehensive Flutter-based mobile application that revolutionizes public transportation in the Philippines by providing real-time jeepney tracking and route information. Built to support **SDG 11.2 — Affordable & Sustainable Transport**.

## Key Features

### For Commuters 🚶‍♀️
- **Live Map Tracking**: Real-time jeepney locations with your current position
- **Route Discovery**: Browse available jeepney routes with detailed information
- **Route Information**: View comprehensive route details including stops and fares

### For Jeepney Drivers 🚌  
- **Driver Registration**: Complete onboarding with jeepney and route details
- **Trip Management**: Start, track, and end trips with GPS monitoring
- **Route Selection**: Choose and manage assigned routes
- **Real-time Broadcasting**: Automatic location sharing to commuters

## Tech Stack

### Frontend
- **Flutter SDK** (>=3.9.0) - Cross-platform mobile development
- **Provider** - State management
- **GoRouter** - Navigation and routing
- **Flutter Map** - Interactive map display with OpenStreetMap
- **Geolocator** - GPS location services
- **Firebase Integration** - Authentication and real-time database

### Key Dependencies
```yaml
flutter_map: ^7.0.2          # Interactive maps
geolocator: ^13.0.1          # GPS location services  
provider: ^6.1.1             # State management
go_router: ^14.2.7           # Navigation
firebase_core: ^3.6.0        # Firebase services
cloud_firestore: ^5.4.3     # Real-time database
firebase_auth: ^5.3.1        # User authentication
```

## 🏗️ App Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │    Firebase     │    │   OpenStreetMap │
│   (Multi-role)  │◄──►│   (Backend)     │    │   (Map Tiles)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       
         │              ┌─────────────────┐              
         │              │   Firestore     │              
         └──────────────►│  (Real-time)    │              
                        └─────────────────┘              
```

## 📱 Project Structure

```
lib/
├── main.dart                    # Application entry point
├── core/
│   ├── models/                  # Data models and entities
│   ├── providers/               # State management (Provider pattern)
│   ├── router/                  # Navigation configuration
│   ├── services/                # Core services (Auth, Firebase, etc.)
│   ├── theme/                   # App theming and styling
│   └── utils/                   # Utility functions and helpers
├── modules/
│   ├── auth/                    # Authentication module
│   │   └── screens/            # Login, registration, role selection
│   ├── commuter/               # Commuter-specific features
│   │   ├── screens/            # Home, map, route list
│   ├── driver/                 # Driver-specific features  
│   │   ├── screens/            # Dashboard, earnings, trip management
└── assets/
    ├── icons/                  # App icons and branding
    ├── images/                 # Image assets
    └── maps/                   # Map-related assets
```

## Getting Started

### Prerequisites
- **Flutter SDK** (version 3.9.0 or higher)
- **Dart SDK** (version 3.0.0 or higher)
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Account** for backend services

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/lucifron28/hackercup.git
cd hackercup
```

2. **Install Flutter dependencies**
```bash
flutter pub get
```

3. **Generate localization files**
```bash
flutter gen-l10n
```

4. **Configure Firebase**
   - Add your `google-services.json` file to `android/app/`
   - Update Firebase configuration in `lib/firebase_options.dart`

5. **Run the application**
```bash
flutter run
```

## 📦 Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (Recommended for Play Store)
```bash
flutter build appbundle --release
```

The built files will be available in:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## 🗺️ Core Features Overview

### Real-Time Tracking System
- GPS-based location broadcasting every 15 seconds
- Firebase Realtime Database for instant updates
- Live map with custom markers for jeepneys and user location
- Automatic route matching and ETA calculations

### Multi-Role User System
- **Role Selection**: Choose between Commuter, Driver, or LGU admin
- **Firebase Authentication**: Secure login and registration
- **Role-based Navigation**: Customized interface per user type
- **Profile Management**: User-specific data and preferences

### Interactive Map Features
- **OpenStreetMap Integration**: Detailed street-level mapping
- **User Location**: Real-time position tracking with permission handling
- **Jeepney Markers**: Color-coded status indicators (Available/Full)
- **Route Visualization**: Interactive route information display

### Data Management
- **Route Information**: Comprehensive route database with stops and schedules  
- **Driver Profiles**: Complete driver and vehicle information
- **Trip History**: Detailed logging of all trips and activities
- **Earnings Tracking**: Financial data for driver compensation

## 🌐 Internationalization

The app supports multiple languages:
- **English** (`en`) - Default language
- **Tagalog/Filipino** (`tl`) - Local language support

Language files are located in `lib/l10n/` and can be extended for additional languages.

## 🔧 Development Commands

```bash
# Development
flutter run                    # Run in debug mode
flutter run --release          # Run in release mode  
flutter hot-reload             # Hot reload during development

# Testing
flutter test                   # Run unit tests
flutter integration_test       # Run integration tests

# Analysis
flutter analyze                # Static code analysis
flutter format lib/            # Format code

# Building
flutter build apk             # Build Android APK
flutter build appbundle       # Build Android App Bundle
flutter clean                 # Clean build artifacts
```

## 📊 Performance Considerations

- **Location Updates**: Optimized 15-second intervals to balance accuracy and battery life
- **Map Caching**: OpenStreetMap tiles cached for offline viewing in poor connectivity areas
- **State Management**: Efficient Provider pattern for minimal rebuilds
- **Firebase Rules**: Optimized security rules for role-based access

## 🇵🇭 Impact on Philippine Transportation

JeepGo addresses critical transportation challenges in the Philippines:
- **Reduced Waiting Time**: Commuters can see real-time jeepney locations
- **Improved Efficiency**: Optimized routes and better passenger distribution
- **Sustainable Transport**: Supports SDG 11.2 goals for accessible public transport
- **Digital Inclusion**: Bridges technology gap in traditional transportation

---