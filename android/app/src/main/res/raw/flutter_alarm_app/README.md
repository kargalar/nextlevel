# Flutter Alarm App

A simple Flutter application that allows users to schedule alarms and receive notifications. This app utilizes the alarm package for managing alarms and notifications effectively.

## Features

- Schedule alarms at specific times.
- Display a list of scheduled alarms.
- Add, edit, and delete alarms.
- Receive notifications when alarms are triggered.
- Customizable alarm sounds.

## Project Structure

```
flutter_alarm_app
├── lib
│   ├── main.dart                     # Entry point of the application
│   ├── models
│   │   ├── alarm.dart                # Defines the Alarm class
│   │   └── notification_data.dart     # Defines the NotificationData class
│   ├── services
│   │   ├── alarm_service.dart         # Manages alarm scheduling and cancellation
│   │   ├── notification_service.dart   # Handles notification display
│   │   └── permission_service.dart     # Manages permission requests
│   ├── screens
│   │   ├── home_screen.dart           # Main screen displaying current alarms
│   │   ├── alarm_list_screen.dart     # Screen for managing scheduled alarms
│   │   └── add_alarm_screen.dart      # Form for creating new alarms
│   ├── widgets
│   │   ├── alarm_card.dart            # Displays individual alarm details
│   │   ├── time_picker_widget.dart     # Allows time selection for alarms
│   │   └── custom_button.dart          # Reusable button component
│   └── utils
│       ├── constants.dart             # Contains constant values
│       └── helpers.dart               # Utility functions
├── android
│   └── app
│       └── src
│           └── main
│               └── res
│                   └── raw
│                       └── alarm_sound.mp3 # Audio file for alarm sound
├── pubspec.yaml                       # Flutter project configuration
└── README.md                          # Project documentation
```

## Setup Instructions

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```
   cd flutter_alarm_app
   ```

3. Install the dependencies:
   ```
   flutter pub get
   ```

4. Run the application:
   ```
   flutter run
   ```

## Usage

- Open the app to view the home screen.
- Use the "Add Alarm" button to create a new alarm.
- Manage existing alarms from the alarm list screen.
- Customize alarm sounds and notification settings as needed.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.