# SelfSnitch - Safe Driving App

A comprehensive Flutter application designed for the 2027 Congressional App Challenge. SelfSnitch provides real-time safety monitoring for teen drivers with parent oversight features, danger zone detection, automatic rerouting, and emergency alerts.

## Features

### Core Functionality
- **Real-time Location Tracking**: Continuous GPS monitoring with speed detection
- **Speed Violation Detection**: Automatic alerts when speed limits are exceeded
- **Danger Zone Detection**: Identifies and warns about high-risk areas (school zones, high-crime areas, construction zones, etc.)
- **Automatic Rerouting**: Suggests safer routes that avoid danger zones
- **Geofencing**: Create custom safe zones with entry/exit notifications

### Parent Mode
- **Teen Location Monitoring**: View real-time locations of all linked teens
- **Alert Dashboard**: Receive instant notifications for speeding, danger zones, and geofence violations
- **Driving History**: Review teen driving patterns and violations
- **Safety Settings**: Configure speed limits, danger zone preferences, and alert thresholds
- **Emergency SOS**: Receive immediate alerts when teen triggers emergency button

### Teen Mode
- **Speedometer Display**: Visual speed indicator with warnings
- **Danger Zone Alerts**: Real-time warnings when approaching or entering danger zones
- **Geofence Notifications**: Alerts when leaving designated safe areas
- **SOS Emergency Button**: One-tap emergency alert to parents
- **Route Suggestions**: Get safer route recommendations

### Safety Features
- **SOS Emergency System**: Instant alerts to parents with location
- **Low Battery Alerts**: Notifications when device battery is low
- **Night Driving Alerts**: Optional warnings for late-night driving
- **Custom Alerts**: Create personalized safety notifications

## Backend API

The app includes a complete Node.js/Express backend with:

- **RESTful API**: Full CRUD operations for all data
- **Real-time Updates**: Socket.io for instant notifications
- **Authentication**: JWT-based secure authentication
- **MongoDB**: NoSQL database for flexible data storage
- **Geospatial Queries**: Efficient location-based queries

### API Endpoints

#### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user
- `POST /api/auth/device-token` - Update device token for push notifications

#### Users
- `GET /api/users/:id` - Get user details
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user
- `GET /api/users/parent/:parentId/teens` - Get all teens for a parent
- `POST /api/users/:teenId/link-parent/:parentId` - Link teen to parent

#### Locations
- `POST /api/locations/:userId` - Update user location
- `GET /api/locations/:userId` - Get user's current location
- `GET /api/locations/:userId/history` - Get location history
- `GET /api/locations/parent/:parentId/teens` - Get locations of all teens

#### Danger Zones
- `POST /api/danger-zones` - Create danger zone
- `GET /api/danger-zones` - Get all danger zones
- `GET /api/danger-zones/:id` - Get specific danger zone
- `PUT /api/danger-zones/:id` - Update danger zone
- `DELETE /api/danger-zones/:id` - Delete danger zone
- `POST /api/danger-zones/check` - Check if location is in danger zone

#### Safety Alerts
- `POST /api/alerts` - Create alert
- `GET /api/alerts/user/:userId` - Get alerts for user
- `GET /api/alerts/parent/:parentId` - Get alerts for parent's teens
- `PATCH /api/alerts/:id/acknowledge` - Acknowledge alert
- `PATCH /api/alerts/:id/resolve` - Resolve alert
- `DELETE /api/alerts/:id` - Delete alert

#### Geofences
- `POST /api/geofences` - Create geofence
- `GET /api/geofences/user/:userId` - Get geofences for user
- `GET /api/geofences/:id` - Get specific geofence
- `PUT /api/geofences/:id` - Update geofence
- `DELETE /api/geofences/:id` - Delete geofence
- `POST /api/geofences/check` - Check if location is inside geofence

#### Routes
- `POST /api/routes/safe` - Calculate safe route
- `GET /api/routes` - Get route history
- `GET /api/routes/:id` - Get specific route

#### Speed Violations
- `POST /api/violations` - Report speed violation
- `GET /api/violations/user/:userId` - Get violations for user
- `GET /api/violations/parent/:parentId` - Get violations for parent's teens
- `PATCH /api/violations/:id/acknowledge` - Acknowledge violation
- `DELETE /api/violations/:id` - Delete violation
- `GET /api/violations/stats/user/:userId` - Get violation statistics

#### Emergency
- `POST /api/emergency/sos` - Send SOS alert
- `GET /api/emergency/contacts` - Get emergency contacts
- `POST /api/emergency/contacts` - Add emergency contact
- `POST /api/emergency/call` - Trigger emergency call

#### Settings
- `GET /api/settings/:userId` - Get user settings
- `PUT /api/settings/:userId` - Update user settings
- `GET /api/settings/defaults` - Get default settings

## Project Structure

```
selfsnitch/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # Main app widget
│   ├── models/                      # Data models
│   │   ├── user_model.dart
│   │   ├── danger_zone.dart
│   │   ├── safety_alert.dart
│   │   ├── geofence.dart
│   │   ├── route_suggestion.dart
│   │   └── speed_violation.dart
│   ├── services/                    # Business logic and API services
│   │   ├── api_service.dart
│   │   ├── location_service.dart
│   │   └── rerouting_service.dart
│   ├── screens/                     # UI screens
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── parent/
│   │   │   └── parent_dashboard.dart
│   │   └── teen/
│   │       └── teen_dashboard.dart
│   ├── widgets/                    # Reusable UI components
│   │   ├── speedometer.dart
│   │   ├── danger_indicator.dart
│   │   ├── alert_card.dart
│   │   └── sos_button.dart
│   └── utils/                      # Utility functions
│       └── constants.dart
├── backend/                        # Node.js backend
│   ├── server.js                   # Express server
│   ├── package.json
│   ├── .env.example
│   ├── models/                     # MongoDB models
│   │   ├── User.js
│   │   ├── DangerZone.js
│   │   ├── SafetyAlert.js
│   │   ├── Geofence.js
│   │   ├── Location.js
│   │   ├── SpeedViolation.js
│   │   └── RouteSuggestion.js
│   ├── routes/                     # API routes
│   │   ├── auth.js
│   │   ├── users.js
│   │   ├── locations.js
│   │   ├── dangerZones.js
│   │   ├── alerts.js
│   │   ├── geofences.js
│   │   ├── routes.js
│   │   ├── violations.js
│   │   ├── emergency.js
│   │   └── settings.js
│   ├── middleware/                 # Express middleware
│   │   └── auth.js
│   └── config/                     # Configuration files
│       └── database.js
└── pubspec.yaml                   # Flutter dependencies
```

## Getting Started

### Prerequisites

- Flutter SDK (version 3.12.2 or higher)
- Dart SDK
- Node.js (version 18 or higher)
- MongoDB (local or cloud)
- Android Studio / Xcode for mobile development

### Installation

#### Flutter App

1. Clone the repository:
```bash
cd selfsnitch
git clone https://github.com/shaypat112/selfsnitch.git
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

#### Backend Server

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file based on `.env.example`:
```bash
cp .env.example .env
```

4. Update the `.env` file with your MongoDB connection string and JWT secret:
```env
MONGODB_URI=mongodb://localhost:27017/selfsnitch
JWT_SECRET=your-very-secure-secret-key
```

5. Start the server:
```bash
npm start
# or for development with auto-restart
npm run dev
```

### Configuration

#### Flutter App Configuration

Update `lib/services/api_service.dart` to point to your backend server:
```dart
static const String _baseUrl = 'http://your-server-ip:3000/api';
```

#### Backend Configuration

- **MongoDB**: Update the connection string in `.env`
- **JWT Secret**: Generate a strong secret key
- **CORS**: Configure allowed origins in `server.js`

## Usage

### For Parents

1. **Register**: Create a parent account
2. **Add Teens**: Link teen accounts to your parent account
3. **Monitor**: View real-time locations and receive alerts
4. **Configure**: Set up geofences and danger zone preferences
5. **Review**: Check driving history and violation statistics

### For Teens

1. **Register**: Create a teen account (optionally link to parent)
2. **Drive**: The app automatically tracks location and speed
3. **Stay Safe**: Receive alerts for danger zones and speeding
4. **Emergency**: Use SOS button for immediate help
5. **Navigate**: Get safer route suggestions

## Technology Stack

### Frontend (Flutter)
- **State Management**: Provider, BLoC pattern
- **Mapping**: flutter_map with OpenStreetMap tiles
- **Location**: geolocator package
- **HTTP**: http package for API calls
- **Real-time**: socket_io_client for WebSocket connections
- **Database**: sqflite for local storage

### Backend (Node.js)
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT (JSON Web Tokens)
- **Real-time**: Socket.io
- **Validation**: Built-in Mongoose validation

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- OpenStreetMap for free map tiles
- All contributors and testers

## Contact

For questions or support, please contact the project maintainer.

---

**Built for the 2027 Congressional App Challenge**
