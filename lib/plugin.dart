import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:convert';
import 'bridge.dart';

/// {@nodoc}
class JVSubSystem with JVDartdocHideObject {
  final MethodChannel _channel;
  JVSubSystem._(this._channel);

  void handleIncomingCall(MethodCall call) {
  }
}

/// Located at `Jivo.session`
/// {@category Session}
class JVSession extends JVSubSystem {
  JVSession._(MethodChannel channel): super._(channel);

  Function _unreadCounterWatcher = (int number) {};

  /// Specifies the preferred server for SDK to connect to Jivo.
  Future<void> setPreferredServer(JVSessionServer server) async {
    await _channel.invokeMethod<void>('session:setPreferredServer',
        {'server': server.toString().split('.').last});
  }

  /// Sets up a connection between SDK and Jivo, by either creating a new session or resuming existing one.
  /// - [channelId] is your channel ID in Jivo (same as widget_id);  
  /// - [userToken] is an unique string that you generate to identify a client, and it determines whether it is necessary to create a new session with a new dialog, or restore an existing one and load the history of the initiated dialog (should be a JWT token).
  Future<void> setup({required String channelId, required String userToken}) async {
    await _channel.invokeMethod<void>('session:setup', {
        'channel_id': channelId,
        'user_token': userToken
    });
  }

  /// Assigns contact info to user, to reach him easier in future.
  Future<void> setContactInfo({String? name, String? email, String? phone, String? brief}) async {
    await _channel.invokeMethod<void>('session:setContactInfo', {
      'name': name ?? '',
      'email': email ?? '',
      'phone': phone ?? '',
      'brief': brief ?? ''
    });
  }

  /// Assigns custom data to user, if needed for your business.
  Future<void> setCustomData(List<JVSessionCustomDataField> fields) async {
    final raw = fields.map(
        (field) => Map.from({
            'title': field.title,
            'key': field.key,
            'content': field.content,
            'link': field.link
        })..removeWhere((k, v) => (v == null))
    ).toList();

    await _channel.invokeMethod<void>('session:setCustomData', jsonEncode(raw));
  }

  /// Closes current connection, clears the local database, and unsubscribes device from Push Notifications.
  Future<void> clear() async {
    await _channel.invokeMethod<void>('session:clear');
  }

  /// Registers the callback that gets called
  /// when counter of unread messages gets changed
  void startWatchingUnreadCounter(Function watcher) {
    _unreadCounterWatcher = watcher;
  }

  /// {@nodoc}
  @override
  void handleIncomingCall(MethodCall call) {
    switch (call.method) {
      case 'session:updateUnreadCounter(number)':
        final number = call.arguments as int;
        _unreadCounterWatcher(number);
    }
  }
}

/// Located at `Jivo.display`
/// {@category Display}
class JVDisplay extends JVSubSystem {
  JVDisplay._(MethodChannel channel): super._(channel);

  Function _extraItemsCallback = (int index) {};
  Function _asksToAppearExecutor = () {};
  Function _willAppearExecutor = () {};
  Function _didAppearExecutor = () {};

  /// Determines whether SDK is currently in UI hierarchy.
  Future<bool> get isOnscreen async {
    final result = await _channel.invokeMethod<bool>('display:isOnscreen').then<bool>((bool? value) => value ?? false);
    return result;
  }

  /// Sets the custom locale for use instead of system one.
  Future<void> setLocale(Locale locale) async {
    await _channel.invokeMethod<void>('display:setLocale', locale.toString());
  }

  /// Customizes captions and texts for some elements.
  Future<void> defineText(String text, {required JVDisplayElement element}) async {
    await _channel.invokeMethod('display:defineText', {
        'element': element.toString().split('.').last,
        'text': text
    });
  }

  /// Customizes colors for some elements.
  Future<void> defineColor(Color color, {required JVDisplayElement element}) async {
    await _channel.invokeMethod('display:defineColor', {
        'element': element.toString().split('.').last,
        'red': color.red,
        'green': color.green,
        'blue': color.blue,
        'alpha': color.alpha
    });
  }

  /// Customizes icons for some elements.
  Future<void> defineImage(String name, {required JVDisplayElement element}) async {
    await _channel.invokeMethod('display:defineImage', {
        'element': element.toString().split('.').last,
        'name': name
    });
  }

  /// Sets your own extra items to display within menu.
  Future<void> setExtraItems(
      {required JVDisplayMenu menu,
      required List<String> captions,
      required Function callback}) async {
    _extraItemsCallback = callback;
    await _channel.invokeMethod<void>('display:setExtraItems',
        {'menu': menu.toString().split('.').last, 'captions': captions});
  }

  /// Displays SDK modally on screen.
  Future<void> present() async {
    await _channel.invokeMethod<void>('display:present');
  }

  /// Registers the callback that gets called
  /// when SDK asks to become visible
  void executeWhenAsksToAppear(Function executor) {
    _asksToAppearExecutor = executor;
  }

  /// Registers the callback that gets called
  /// when SDK is going to get shown
  void executeWhenWillAppear(Function executor) {
    _willAppearExecutor = executor;
    JVSessionServer.asia;
  }

  /// Registers the callback that gets called
  /// when SDK is going to get hidden
  void executeWhenDidDisappear(Function executor) {
    _didAppearExecutor = executor;
  }

  /// {@nodoc}
  @override
  void handleIncomingCall(MethodCall call) {
    switch (call.method) {
      case 'display:setExtraItems:callback':
        final index = call.arguments as int;
        _extraItemsCallback(index);

      case 'display:asksToAppear':
        _asksToAppearExecutor();

      case 'display:willAppear':
        _willAppearExecutor();

      case 'display:didDisappear':
        _didAppearExecutor();
    }
  }

  /// Sets the theme mode for the chat UI.
  /// [JVThemeMode.system] = follow system, [light] = force light, [dark] = force dark.
  Future<void> setThemeMode(JVThemeMode mode) async {
    await _channel.invokeMethod<void>(
        'display:setThemeMode', mode.name);
  }
}

/// Located at `Jivo.notifications`
/// {@category Notifications}
class JVNotifications extends JVSubSystem {
  JVNotifications._(MethodChannel channel): super._(channel);

  /// Specifies when SDK should request access to Push Notifications.
  Future<void> setPermissionAsking(
      JVNotificationsPermissionAskingMoment moment) async {
    await _channel.invokeMethod<void>('notifications:setPermissionAsking',
        {'moment': moment.toString().split('.').last});
  }

  /// Associates the Push Token with current user using his userToken in raw-binary form.
  Future<void> setPushToken(String token) async {
    await _channel.invokeMethod<void>(
        'notification:setPushToken', token);
  }

  /// {@nodoc}
  @override
  void handleIncomingCall(MethodCall call) {
  }
}

/// Located at `Jivo.debugging`
/// {@category Debugging}
class JVDebugging extends JVSubSystem {
  JVDebugging._(MethodChannel channel): super._(channel);

  Function _archiveLogsCallback = (String path) {};

  /// Sets the level of logging verbosity
  Future<void> setLevel(JVDebuggingLevel level) async {
    await _channel.invokeMethod<void>(
        'debugging:level', {'level': level.toString().split('.').last});
  }

  /// Performs archiving of local log entries
  /// and returns a link to the created archive
  /// via completion block with status
  Future<void> archiveLogs({required Function completion}) async {
    _archiveLogsCallback = completion;
    await _channel.invokeMethod<void>('debugging:archiveLogs');
  }

  /// {@nodoc}
  @override
  void handleIncomingCall(MethodCall call) {
    switch (call.method) {
      case 'debugging:archiveLogs:callback':
        final url = call.arguments as String;
        _archiveLogsCallback(url);
    }
  }
}

/// {@nodoc}
final class JivoPlugin extends PlatformInterface {
  static final JivoPlugin instance = JivoPlugin._();
  static const _channel = MethodChannel('jivosdk_plugin');
  final JVSession session;
  final JVDisplay display;
  final JVNotifications notifications;
  final JVDebugging debugging;

  static final Object _token = Object();
  JivoPlugin._()
      : session = JVSession._(_channel),
        display = JVDisplay._(_channel),
        notifications = JVNotifications._(_channel),
        debugging = JVDebugging._(_channel),
        super(token: _token) {
    _channel.setMethodCallHandler((MethodCall call) async {
      session.handleIncomingCall(call);
      display.handleIncomingCall(call);
      notifications.handleIncomingCall(call);
      debugging.handleIncomingCall(call);
      return true;
    });
  }
}

/// {@nodoc}
mixin JVDartdocHideObject {
  /// {@nodoc}
  @override
  Type get runtimeType => super.runtimeType;

  /// {@nodoc}
  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  /// {@nodoc}
  @override
  String toString() {
    return super.toString();
  }

  /// {@nodoc}
  @override
  int get hashCode => super.hashCode;

  /// {@nodoc}
  @override
  bool operator == (Object other) => (super == other);
}
