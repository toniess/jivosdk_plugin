import 'plugin.dart';

/// Entry point
final class Jivo with JVDartdocHideObject {
    /// Responsible for everything related to the communication session, such as connection and client data.
    /// {@category Session}
    static JVSession get session => JivoPlugin.instance.session;

    /// Responsible for everything related to the visual representation of chat on screen.
    /// {@category Display}
    static JVDisplay get display => JivoPlugin.instance.display;

    /// Contains methods responsible for setting up and processing Push Notifications.
    /// {@category Notifications}
    static JVNotifications get notifications => JivoPlugin.instance.notifications;

    /// Helps debugging the SDK
    /// {@category Debugging}
    static JVDebugging get debugging => JivoPlugin.instance.debugging;

    /// {@nodoc}
    Jivo();
}

/// Primary Jivo servers, by geographical region
/// {@category Session}
enum JVSessionServer {
    auto,
    asia,
    europe,
    russia
}

/// Custom Data Field for user
/// {@category Session}
class JVSessionCustomDataField with JVDartdocHideObject {
    String? title;
    String? key;
    String content;
    String? link;
    JVSessionCustomDataField(this.title, this.key, this.content, this.link);
}

/// Theme mode for the chat UI.
/// {@category Display}
enum JVThemeMode {
  /// Follow system setting
  system,
  /// Force light
  light,
  /// Force dark
  dark
}

/// UI elements available for customization
/// {@category Display}
enum JVDisplayElement {
    headerIcon,
    headerTitle,
    headerSubtitle,
    outgoingElements,
    messageHello,
    messageOffline,
    replyPlaceholder,
    replyPrefill,
    attachCamera,
    attachLibrary,
    attachFile,
    rateFormPreSubmitTitle,
    rateFormPostSubmitTitle,
    rateFormCommentPlaceholder,
    rateFormSubmitCaption
}

/// Menus available for customization
/// {@category Display}
enum JVDisplayMenu {
    attach
}

/// Moment to request access to Push Notifications
/// {@category Notifications}
enum JVNotificationsPermissionAskingMoment {
    never,
    onconnect,
    onappear,
    onsend
}

/// Level of logging verbosity, relates to Jivo.debugging namespace
/// {@category Debugging}
enum JVDebuggingLevel {
  silent,
  full
}
