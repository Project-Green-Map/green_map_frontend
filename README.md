# green_map_frontend

The Flutter frontend for the Green Maps project.

## Installation

- Build a fresh Flutter project locally called `com.green_map.green_map`.
- Pull from Git, overwrite any local files
- Use an Android VM to test the app (Android Studio has a good Virtual Device Manager)
- Place our .env file in the root directory. We'll send you this directly, it has API secrets. :eyes:

## Project Structure
```
├── android                 # Android build files
├── build                   # Flutter temp files
├── ios                     # iOS build files
├── lib                     # Main program code
    ├── dummy_data          # "Fake" data to limit API requests made during testing.
    ├── models              # Models of structures from e.g. JSONs for easy porting to Dart
    ├── services            # Direct interaction with APIs
    ├── main.dart           # First code run by Flutter
    └── MyApp.dart          # Screen-related code.
├── test                    # Unit tests
├── web                     # App icons
├── .env                    # App secrets, API keys
├── pubspec.yaml            # Imports and includes
└── README.md

```