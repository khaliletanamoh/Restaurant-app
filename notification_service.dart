import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/profile/user_repository.dart';

/// Saves the device's FCM token on the user's profile (so Cloud Functions can notify the
/// customer) and subscribes staff and managers to the 'staff' topic (new order alerts).
class NotificationService {
  NotificationService(this._users);

  final UserRepository _users;
  StreamSubscription<String>? _refreshSub;

  Future<void> register(AppUser user) async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(); // Android 13+ asks the user
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await messaging.getToken();
    if (token != null) await _users.saveFcmToken(user.uid, token);

    await _refreshSub?.cancel();
    _refreshSub = messaging.onTokenRefresh.listen((t) => _users.saveFcmToken(user.uid, t));

    if (user.role != UserRole.customer) {
      await messaging.subscribeToTopic('staff');
    }
  }

  Future<void> unregister() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    await FirebaseMessaging.instance.unsubscribeFromTopic('staff');
  }
}
