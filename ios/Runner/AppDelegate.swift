import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set up notification delegate for local notifications (used for iOS alarms)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    // Enable background fetch for data synchronization
    // iOS will call performFetchWithCompletionHandler when appropriate
    // (typically when device is charging and on WiFi)
    UIApplication.shared.setMinimumBackgroundFetchInterval(
      UIApplication.backgroundFetchIntervalMinimum
    )
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Background Fetch
  // Called by iOS when it decides to wake the app for background sync
  // This works even when the app is completely closed
  override func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    NSLog("📱 iOS Background Fetch triggered - app may be closed")
    
    // WorkManager will handle the actual sync work
    // We just need to tell iOS that new data is available
    // The Flutter WorkManager plugin will execute the callbackDispatcher
    
    // Give iOS feedback about the fetch result
    // .newData = we fetched data successfully
    // .noData = no new data available
    // .failed = fetch failed
    completionHandler(.newData)
    
    NSLog("✅ Background fetch completed")
  }
}
