import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class SessionIdentity {
  const SessionIdentity({required this.role});

  final String role;
}

class SessionCookieService {
  SessionCookieService({CookieJar? cookieJar})
    : cookieJar = cookieJar ?? CookieJar();

  final CookieJar cookieJar;

  CookieManager createInterceptor() => CookieManager(cookieJar);

  Future<SessionIdentity?> readIdentity(String serverUrl) async {
    final uri = Uri.parse('$serverUrl/api/');
    final cookies = await cookieJar.loadForRequest(uri);
    final authCookie = cookies
        .where((cookie) => cookie.name == 'auth')
        .firstOrNull;
    if (authCookie == null || authCookie.value.isEmpty) {
      return null;
    }

    try {
      var decoded = authCookie.value;
      for (var index = 0; index < 2 && decoded.contains('%'); index++) {
        decoded = Uri.decodeComponent(decoded);
      }
      final value = jsonDecode(decoded);
      if (value is! Map<String, dynamic>) {
        return const SessionIdentity(role: 'user');
      }
      final role = value['role'];
      return SessionIdentity(
        role: role is String && role.isNotEmpty ? role : 'user',
      );
    } catch (_) {
      return const SessionIdentity(role: 'user');
    }
  }

  Future<void> clear() => cookieJar.deleteAll();
}
