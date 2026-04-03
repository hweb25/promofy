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

  // TODO: Replace with values from google-services.json after Firebase Android app setup
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'promofy-app',
    storageBucket: 'promofy-app.firebasestorage.app',
  );

  // TODO: Replace with values from GoogleService-Info.plist after Firebase iOS app setup
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'promofy-app',
    storageBucket: 'promofy-app.firebasestorage.app',
    iosBundleId: 'com.promofy.app',
  );
}
