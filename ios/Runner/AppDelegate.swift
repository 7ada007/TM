import Flutter
import UIKit

/// Blocks screen recording while leaving screenshots working.
///
/// iOS reports recording separately from screenshots, so this maps onto the
/// requirement cleanly. `UIScreen.isCaptured` is true whenever the display is
/// being recorded, mirrored or AirPlayed, and `capturedDidChangeNotification`
/// fires on every transition. Screenshots do not set it, so they keep working.
///
/// While capture is active a black cover window is placed above the app. That
/// cover is what lands in the recording. It is removed as soon as capture stops.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  private static let channelName = "com.tareeqalmajd.studentapp/screen_guard"

  private var eventSink: FlutterEventSink?
  private var coverWindow: UIWindow?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(captureStateDidChange),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    applyCaptureState()
    return result
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterEventChannel(
      name: AppDelegate.channelName,
      binaryMessenger: engineBridge.binaryMessenger
    )
    channel.setStreamHandler(self)
  }

  @objc private func captureStateDidChange() {
    applyCaptureState()
  }

  /// Any attached screen being captured counts, which covers mirroring to an
  /// external display as well as on-device recording.
  private var isCaptured: Bool {
    UIScreen.screens.contains { $0.isCaptured }
  }

  private func applyCaptureState() {
    let captured = isCaptured

    if captured {
      showCover()
    } else {
      hideCover()
    }

    eventSink?(captured)
  }

  private func showCover() {
    guard coverWindow == nil else { return }

    let scene =
      UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
      ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first

    let cover: UIWindow
    if let scene = scene {
      cover = UIWindow(windowScene: scene)
    } else {
      cover = UIWindow(frame: UIScreen.main.bounds)
    }

    cover.windowLevel = .alert + 1
    cover.backgroundColor = .black
    cover.isUserInteractionEnabled = false

    let controller = UIViewController()
    controller.view.backgroundColor = .black

    let label = UILabel()
    label.text = "تسجيل الشاشة غير مسموح داخل التطبيق"
    label.textColor = .white
    label.textAlignment = .center
    label.numberOfLines = 0
    label.font = .systemFont(ofSize: 17, weight: .semibold)
    label.translatesAutoresizingMaskIntoConstraints = false

    controller.view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
      label.leadingAnchor.constraint(
        greaterThanOrEqualTo: controller.view.leadingAnchor, constant: 24),
      label.trailingAnchor.constraint(
        lessThanOrEqualTo: controller.view.trailingAnchor, constant: -24),
    ])

    cover.rootViewController = controller
    cover.isHidden = false
    coverWindow = cover
  }

  private func hideCover() {
    coverWindow?.isHidden = true
    coverWindow = nil
  }
}

extension AppDelegate: FlutterStreamHandler {
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    events(isCaptured)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}
