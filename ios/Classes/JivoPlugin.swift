import UIKit
import Flutter
import JivoSDK

public class JivoPlugin: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "jivosdk_plugin", binaryMessenger: registrar.messenger())
        let plugin = JivoPlugin(channel: channel)
        
        registrar.addApplicationDelegate(plugin)
        registrar.addMethodCallDelegate(plugin, channel: channel)
    }
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        
        super.init()
        
        Jivo.session.listenToUnreadCounter { number in
            channel.invokeMethod("session:updateUnreadCounter(number)", arguments: number)
        }

        Jivo.display.listenToAppearanceRequest {
            channel.invokeMethod("display:asksToAppear", arguments: nil)
        }

        Jivo.display.listenToWillAppear {
            channel.invokeMethod("display:willAppear", arguments: nil)
        }

        Jivo.display.listenToDidDisappear {
            channel.invokeMethod("display:didDisappear", arguments: nil)
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print(call.method);
        
        switch call.method {
        case "session:setPreferredServer":
            defer {
                result(nil)
            }

            guard let params = call.arguments as? [String: String],
                  let server = params["server"]
            else {
                return
            }
            
            switch server {
            case "auto":
                Jivo.session.setPreferredServer(.auto)
            case "asia":
                Jivo.session.setPreferredServer(.asia)
            case "europe":
                Jivo.session.setPreferredServer(.europe)
            case "russia":
                Jivo.session.setPreferredServer(.russia)
            default:
                break
            }
            
        case "session:setup":
            defer {
                result(nil)
            }

            guard let params = call.arguments as? [String: String],
                  let channelId = params["channel_id"]
            else {
                return
            }

            if let userToken = params["user_token"] {
                Jivo.session.setup(widgetID: channelId, clientIdentity: .jwt(userToken))
            }
            else {
                Jivo.session.setup(widgetID: channelId, clientIdentity: .anonymous)
            }

        case "session:setContactInfo":
            defer {
                result(nil)
            }

            guard let params = call.arguments as? [String: String]
            else {
                return
            }
            
            Jivo.session.setContactInfo(JVSessionContactInfo(
                name: params["name"],
                email: params["email"],
                phone: params["phone"],
                brief: params["brief"]
            ))
            
        case "session:setCustomData":
            defer {
                result(nil)
            }

            guard let raw = call.arguments as? String else {
                return
            }

            guard let data = raw.data(using: .utf8) else {
                return
            }

            guard let fields = (try? JSONSerialization.jsonObject(with: data)) as? [[String: String]] else {
                return
            }

            Jivo.session.setCustomData(fields: fields.compactMap { field in
                guard let content = field["content"]
                else {
                    return nil
                }
                
                return JVSessionCustomDataField(
                    title: field["title"],
                    key: field["key"],
                    content: content,
                    link: field["link"]
                )
            })
            
        case "session:clear":
            defer {
                result(nil)
            }

            Jivo.session.shutDown()
            
        case "display:isOnscreen":
            result(Jivo.display.isOnscreen)
            
        case "display:setLocale":
            defer {
                result(nil)
            }

            guard let identifier = call.arguments as? String
            else {
                return
            }
            
            let locale = Locale(identifier: identifier)
            Jivo.display.setLocale(locale)

        case "display:setThemeMode":
            defer {
                result(nil)
            }

            guard let raw = call.arguments as? String else {
                return
            }

            switch raw {
                case "light":
                    Jivo.display.setTheme(.light)
                case "dark":
                    Jivo.display.setTheme(.dark)
                default:
                    Jivo.display.setTheme(.unspecified)
            }
            
        case "display:defineText":
            defer {
                result(nil)
            }

            guard let params = call.arguments as? [String: AnyHashable],
                  let elementName = params["element"] as? String,
                  let text = params["text"] as? String
            else {
                return
            }

            if let element = decodeUiElement(name: elementName) {
                Jivo.display.define(text: text, forElement: element)
            }
            
        case "display:defineImage":
            defer {
                result(nil)
            }

            guard let params = call.arguments as? [String: AnyHashable],
                  let elementName = params["element"] as? String,
                  let name = params["name"] as? String
            else {
                return
            }

            if let element = decodeUiElement(name: elementName), let image = UIImage(named: name)  {
                Jivo.display.define(image: image, forElement: element)
            }
            
        case "display:defineColor":
            defer {
                result(nil)
            }

            guard let params = call.arguments as? [String: AnyHashable],
                  let elementName = params["element"] as? String,
                  let red = params["red"] as? Int,
                  let green = params["green"] as? Int,
                  let blue = params["blue"] as? Int,
                  let alpha = params["alpha"] as? Int
            else {
                return
            }

            let r = CGFloat(red) / CGFloat(255)
            let g = CGFloat(green) / CGFloat(255)
            let b = CGFloat(blue) / CGFloat(255)
            let a = CGFloat(alpha) / CGFloat(255)
            let color = UIColor(red: r, green: g, blue: b, alpha: a)

            if let element = decodeUiElement(name: elementName) {
                Jivo.display.define(color: color, forElement: element)
            }

        case "display:setExtraItems":
            defer {
                result(nil)
            }

            guard let params = call.arguments as? [String: AnyHashable],
                  let menu = params["menu"] as? String,
                  let captions = params["captions"] as? [String]
            else {
                return
            }
            
            switch menu {
            case "attach":
                Jivo.display.setExtraItems(menu: .attach, captions: captions) { [channel] index in
                    channel.invokeMethod("display:setExtraItems:callback", arguments: index)
                }
                
            default:
                break
            }
            
        case "display:present":
            defer {
                result(nil)
            }

            guard let container = UIApplication.shared.windows.first?.rootViewController
            else {
                return
            }
            
            Jivo.display.present(over: container)
            
        case "notifications:setPermissionAsking":
            defer {
                result(nil)
            }

            guard let params = call.arguments as? [String: AnyHashable],
                  let moment = params["moment"] as? String
            else {
                return
            }
            
            switch moment {
            case "never":
                Jivo.notifications.setPermissionAsking(at: .never)
            case "sessionSetup", "onconnect":
                Jivo.notifications.setPermissionAsking(at: .sessionSetup)
            case "displayOnscreen", "onappear":
                Jivo.notifications.setPermissionAsking(at: .displayOnscreen)
            case "clientAction", "onsend":
                Jivo.notifications.setPermissionAsking(at: .clientAction)
            default:
                break
            }
        
        case "notification:setPushToken":
            defer {
                result(nil)
            }
            
        case "debugging:level":
            defer {
                result(nil)
            }

            guard let params = call.arguments as? [String: AnyHashable],
                  let level = params["level"] as? String
            else {
                return
            }
            
            switch level {
            case "silent":
                Jivo.debugging.setLevel(.silent)
            case "full":
                Jivo.debugging.setLevel(.full)
            default:
                break
            }
            
        case "debugging:archiveLogs":
            defer {
                result(nil)
            }

            Jivo.debugging.exportArchive { [channel] status, url in
                let path = (url?.absoluteString) ?? String()
                channel.invokeMethod("debugging:archiveLogs:callback", arguments: path)
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func decodeUiElement(name: String) -> JVDisplayElement? {
        switch name {
        case "headerIcon":
            return .headerIcon
        case "headerTitle":
            return .headerTitle
        case "headerSubtitle":
            return .headerSubtitle
        case "outgoingElements":
            return .outgoingElements
        case "messageWelcome", "messageHello":
            return .messageWelcome
        case "messageOffline":
            return .messageOffline
        case "replyPlaceholder":
            return .replyPlaceholder
        case "replyPrefill":
            return .replyPrefill
        case "attachCamera":
            return .attachCamera
        case "attachLibrary":
            return .attachLibrary
        case "attachFile":
            return .attachFile
        case "rateFormPreSubmitTitle":
            return .rateFormPreSubmitTitle
        case "rateFormPostSubmitTitle":
            return .rateFormPostSubmitTitle
        case "rateFormCommentPlaceholder":
            return .rateFormCommentPlaceholder
        case "rateFormSubmitCaption":
            return .rateFormSubmitCaption
        default:
            return nil
        }
    }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        if let remoteNotification = launchOptions[UIApplication.LaunchOptionsKey.remoteNotification.rawValue] {
            return Jivo.notifications.handleLaunch(options: [.remoteNotification: remoteNotification])
        }
        
        return false
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Jivo.notifications.setPushToken(data: deviceToken)
    }
    
    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Jivo.notifications.setPushToken(data: nil)
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        if Jivo.notifications.handleIncoming(userInfo: userInfo, completionHandler: completionHandler) {
            return true
        }
        else {
            return false
        }
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Jivo.notifications.didReceive(response: response)
        completionHandler()
    }
}
