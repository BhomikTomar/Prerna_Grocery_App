# prerna

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Setup

This project uses Firebase. To set up Firebase for development:

1. **Install FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Configure Firebase:**
   ```bash
   flutterfire configure
   ```

3. **Download configuration files:**
   - Download `google-services.json` from Firebase Console and place it in `android/app/`
   - Download `GoogleService-Info.plist` from Firebase Console and place it in `ios/Runner/`

4. **Generate Firebase options:**
   ```bash
   flutterfire configure
   ```
   This will generate the `lib/firebase_options.dart` file with your actual API keys.

**Note:** The `firebase_options.dart` and `google-services.json` files are not included in version control for security reasons. Use the template files as reference and generate your own configuration files.
