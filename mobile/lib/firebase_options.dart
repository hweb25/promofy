// File generated manually for Promofy Firebase configuration
// Replace placeholder values with your Firebase project config after adding apps
// You can also regenerate this using: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isIOS) {
      return ios;
    } else if (Platform.isAndroid) {
      return android;
    }
    throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLEdEqg5mDY8lLHnM7u1WP9MxmMcUL75s',
    appId: '1:990656781474:android:94bf6676227a0ce26a4bfb',
    messagingSenderId: '990656781474',
    projectId: 'promofy-67506',
    storageBucket: 'promofy-67506.firebasestorage.app',
  );

  // TODO: Update with iOS-specific values from GoogleService-Info.plist once iOS app is added
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCLEdEqg5mDY8lLHnM7u1WP9MxmMcUL75s',
    appId: '1:990656781474:android:94bf6676227a0ce26a4bfb', // Replace with iOS app ID
    messagingSenderId: '990656781474',
    projectId: 'promofy-67506',
    storageBucket: 'promofy-67506.firebasestorage.app',
    iosBundleId: 'com.promofy.app',
  );
}
