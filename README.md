# hackercup

# Jeepney Tracker - SDG 11.2 Sustainable Transport

A comprehensive cross-platform mobile application solution built with Flutter that advances **SDG 11.2 — Affordable & Sustainable Transport** by delivering real-time jeepney tracking for Philippine commuters.

## 🌟 Features

### MVP Requirements (48h Implementation)

- **Multi-Role Support**: Commuter, Jeepney Driver, LGU Dispatcher interfaces
- **Real-Time Tracking**: Driver GPS broadcasting every 15 seconds via MQTT/WebSocket
- **Live Map Display**: OpenStreetMap with jeepney icons and ETA countdown
- **Offline Functionality**: SMS keyword "JEEP \<route>" returns next 3 ETAs
- **Cached Maps**: Offline map tiles for dead zones
- **Monetization**: AdMob integration with revenue sharing for drivers
- **Internationalization**: English and Tagalog support

### Backend Stack
- **FastAPI** with REST + WebSocket endpoints
- **PostgreSQL + PostGIS** for geospatial data
- **Redis** for real-time state caching
- **OSRM** for route calculation and ETA estimation
- **Firebase Cloud Messaging** for push notifications
- **Twilio SMS** gateway for offline functionality

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   FastAPI       │    │   PostgreSQL    │
│   (Multi-role)  │◄──►│   Backend       │◄──►│   + PostGIS     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐    ┌─────────────────┐
         │              │     Redis       │    │      OSRM       │
         └──────────────►│   (Real-time)   │    │   (Routing)     │
                        └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (>=3.9.0)
- **Dart SDK** (>=3.0.0)
- **Docker & Docker Compose**
- **Python 3.11+** (for local backend development)

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/jeepney-tracker.git
cd jeepney-tracker
```

### 2. Flutter App Setup

```bash
# Install Flutter dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Run the app
flutter run
```

### 3. Backend Setup

#### Using Docker (Recommended)

```bash
cd backend

# Start all services
docker-compose up -d

# Check service status
docker-compose ps
```

Services available at:
- **FastAPI Backend**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## 📱 Mobile App Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── models/              # Data models
│   ├── services/            # Core services
│   ├── router/              # Navigation
│   └── theme/               # UI themes
├── modules/
│   ├── auth/                # Authentication
│   ├── driver/              # Driver interface
│   ├── commuter/            # Commuter interface
│   └── lgu/                 # LGU dispatcher
└── l10n/                    # Internationalization
    ├── app_en.arb          # English strings
    └── app_tl.arb          # Tagalog strings
```

## 🌐 Key API Endpoints

- `POST /auth/login` - User authentication
- `GET /routes` - Get all available routes
- `GET /routes/{route_id}/eta` - Get ETAs for specific route
- `WebSocket /ws/vehicles` - Real-time location updates
- `POST /sms` - Handle SMS ETA requests

## 🗺️ Features by User Role

### 👤 Commuter Features
- View nearby jeepneys with real-time locations
- Get ETA estimates for different routes
- Track specific jeepneys
- Offline SMS functionality
- Multi-language support

### 🚌 Driver Features
- Start/end trips with GPS tracking
- Manage passenger count and seat availability
- View daily earnings and trip statistics
- Ad revenue sharing

### 🏛️ LGU Dispatcher Features
- Fleet management dashboard
- Real-time monitoring of all jeepneys
- Route performance analytics
- Emergency broadcast messaging
- SDG 11.2 impact metrics

## 💰 Monetization & SDG Impact

- AdMob banner/interstitial ads in commuter app
- Daily CSV export of ad revenue per driver
- CO2 emissions tracking
- Accessibility and affordability metrics

## 🛠️ Development Commands

```bash
# Flutter
flutter run              # Run app
flutter test             # Run tests
flutter build apk        # Build Android APK

# Backend
docker-compose up -d     # Start services
docker-compose logs -f   # View logs
```

**Made with ❤️ for sustainable transport in the Philippines** 🇵🇭

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
