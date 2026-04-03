import Flutter
import UIKit
import Firebase
import GoogleMaps
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()

    // Initialize Google Maps - replace with your API key
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_KEY")

    // Register for push notifications
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    // Set messaging delegate
    Messaging.messaging().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle APNs token
  override func application(_ application: UIApplication,
                           didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    // Token is handled by the Flutter side via firebase_messaging package
  }
}
