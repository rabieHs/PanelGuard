# AIDO Sensor App

A Flutter application that reads real-time sensor data from Firebase Realtime Database, displays the latest values, sends data to a prediction API, and shows a chart comparing luminosity and power values.

## Features

- Real-time data fetching from Firebase Realtime Database
- Display of latest sensor values (temperature, humidity, luminosity, dust, current, voltage, power)
- API integration to get prediction level
- Chart visualization comparing luminosity and power values from the last 20 readings
- Responsive UI design

## Setup

### Prerequisites

- Flutter SDK (latest version)
- Firebase account with Realtime Database set up
- API endpoint for predictions

### Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Set up Realtime Database with the following structure:
   ```
   sensors
     ├── [timestamp1]
     │   ├── courant: double
     │   ├── humidity: double
     │   ├── luminosite: double
     │   ├── poussiere: double
     │   ├── puissance: double
     │   ├── temperature: double
     │   └── tension: double
     ├── [timestamp2]
     │   ├── ...
     └── ...
   ```
3. Get your Firebase configuration:

   - Go to Project Settings > General
   - Scroll down to "Your apps" section
   - Add a Flutter app if you haven't already
   - Download the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS)

4. Update the `firebase_options.dart` file with your Firebase configuration

### API Setup

1. Ensure your prediction API is running at the specified URL (default: `http://localhost:5000/predict`)
2. The API should accept POST requests with JSON data in the following format:
   ```json
   {
     "courant": 52.9,
     "humidity": 42.4,
     "luminosite": 54612.49609,
     "poussiere": 524.21875,
     "puissance": 676.90839,
     "temperature": 26.7,
     "tension": 12.796
   }
   ```
3. The API should return a response with a `niveau` field containing an integer value

## Running the App

1. Clone this repository
2. Navigate to the project directory
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app

## Project Structure

- `lib/models/`: Data models
- `lib/services/`: Firebase and API services
- `lib/screens/`: App screens
- `lib/widgets/`: Reusable UI components
- `lib/main.dart`: App entry point

## Dependencies

- `firebase_core`: Firebase Core functionality
- `firebase_database`: Firebase Realtime Database
- `fl_chart`: Chart visualization
- `http`: API requests
