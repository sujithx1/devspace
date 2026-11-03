import Flutter
import UIKit
import WidgetKit

/// Flutter side: `lib/core/services/widget_bridge.dart`.
///
/// Publishes the widget snapshot to the App Group, reloads WidgetKit, and
/// hands Flutter the actions queued by widgets, Shortcuts and `devspace://`
/// links (received here as a scene delegate, including on a cold start).
final class WidgetBridge: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
    private let channel: FlutterMethodChannel
    private var observer: NSObjectProtocol?

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        observer = NotificationCenter.default.addObserver(
            forName: DevSpaceShared.actionsQueued, object: nil, queue: .main
        ) { [weak self] _ in self?.notifyFlutter() }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "tech.magadh.devspace/widgets", binaryMessenger: registrar.messenger())
        let instance = WidgetBridge(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addSceneDelegate(instance)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "saveSnapshot":
            guard let json = call.arguments as? String else {
                result(FlutterError(code: "bad_args", message: "Expected a JSON string", details: nil))
                return
            }
            DevSpaceShared.saveSnapshotJSON(json)
            result(nil)
        case "reloadWidgets":
            WidgetCenter.shared.reloadAllTimelines()
            result(nil)
        case "takeActions":
            result(DevSpaceShared.takeActionsJSON())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: Scene events

    func scene(
        _ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions?
    ) -> Bool {
        connectionOptions?.urlContexts.forEach { receive($0.url) }
        return false
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        let ours = URLContexts.filter { $0.url.scheme == DevSpaceShared.urlScheme }
        ours.forEach { receive($0.url) }
        return !ours.isEmpty
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        notifyFlutter()
    }

    private func receive(_ url: URL) {
        guard url.scheme == DevSpaceShared.urlScheme else { return }
        DevSpaceShared.enqueue(["type": "url", "url": url.absoluteString])
    }

    private func notifyFlutter() {
        channel.invokeMethod("actionsAvailable", arguments: nil)
    }
}
