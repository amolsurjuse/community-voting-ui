import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/storage/secure_store.dart';
import '../domain/models/organizer.dart';
import '../domain/repositories.dart';

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({
    required Uri gatewayBaseUri,
    required SecureStore secureStore,
    http.Client? client,
  })  : _baseUri = gatewayBaseUri,
        _secureStore = secureStore,
        _client = client ?? http.Client();

  final Uri _baseUri;
  final SecureStore _secureStore;
  final http.Client _client;
  Organizer? _current;

  @override
  Organizer? get current => _current;

  @override
  Future<Organizer?> restoreSession() async {
    var token = await _secureStore.read(SecureKey.organizerAuthToken);
    final profile = await _secureStore.read(SecureKey.organizerProfile);
    if (token == null || profile == null) {
      await _clearAuth();
      return null;
    }
    if (_isExpired(token)) {
      token = await _refreshAccessToken();
      if (token == null) {
        await _clearAuth();
        return null;
      }
    }
    final roles = _jwtClaims(token)['roles'];
    if (roles is! List || !roles.contains('COMMUNITY_VOTING_USER')) {
      await _clearAuth();
      return null;
    }
    _current = _profileFromJson(jsonDecode(profile) as Map<String, dynamic>);
    return _current;
  }

  Future<String?> _refreshAccessToken() async {
    final refresh = await _secureStore.read(SecureKey.organizerRefreshToken);
    final device = await _secureStore.read(SecureKey.authDeviceId);
    if (refresh == null || device == null) return null;
    try {
      final response = await _client.post(
        _baseUri.resolve('/auth/api/auth/refresh'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh, 'deviceId': device}),
      );
      final body = _decode(response);
      final accessToken = body['accessToken'] as String?;
      final rotatedRefresh = body['refreshToken'] as String?;
      if (accessToken == null || rotatedRefresh == null) return null;
      await _secureStore.write(SecureKey.organizerAuthToken, accessToken);
      await _secureStore.write(
        SecureKey.organizerRefreshToken,
        rotatedRefresh,
      );
      return accessToken;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Organizer> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final names = fullName.trim().split(RegExp(r'\s+'));
    final response = await _client.post(
      _baseUri.resolve('/auth/api/auth/register'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': names.first,
        'lastName': names.length > 1 ? names.skip(1).join(' ') : '-',
        'phoneNumber': phone,
        'address': null,
        'application': 'COMMUNITY_VOTING',
      }),
    );
    final body = _decode(response);
    final token = body['accessToken'] as String?;
    final refresh = body['refreshToken'] as String?;
    final deviceId = body['deviceId'] as String?;
    if (token == null || refresh == null || deviceId == null) {
      throw const RepositoryException(
          'Authentication response was incomplete.');
    }
    final claims = _jwtClaims(token);
    final roles = claims['roles'];
    if (roles is! List || !roles.contains('COMMUNITY_VOTING_USER')) {
      throw const RepositoryException(
        'This account is not authorized for Community Voting.',
      );
    }
    final organizer = Organizer(
      id: claims['uid'] as String? ?? '',
      fullName: fullName,
      email: claims['sub'] as String? ?? email,
      phone: _mask(phone),
    );
    await _secureStore.write(SecureKey.organizerAuthToken, token);
    await _secureStore.write(SecureKey.organizerRefreshToken, refresh);
    await _secureStore.write(SecureKey.authDeviceId, deviceId);
    await _storeProfile(organizer);
    return _current = organizer;
  }

  @override
  Future<void> resendEmailCode() async {
    final email = _current?.email;
    if (email == null) throw const RepositoryException('Sign in again.');
    final response = await _client.post(
      _baseUri.resolve('/auth/api/auth/email-verification/resend'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    _decode(response);
  }

  @override
  Future<Organizer> verifyEmail(String code) async {
    final response = await _client.post(
      _baseUri.resolve('/auth/api/auth/email-verification/verify'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'token': code}),
    );
    _decode(response);
    final updated = _requireCurrent().copyWith(emailVerified: true);
    await _storeProfile(updated);
    return _current = updated;
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    throw const RepositoryException(
      'Phone verification is not available from the authentication service yet.',
    );
  }

  @override
  Future<Organizer> verifyPhoneOtp(String code) async {
    throw const RepositoryException(
      'Phone verification is not available from the authentication service yet.',
    );
  }

  @override
  Future<void> signOut() async {
    final refresh = await _secureStore.read(SecureKey.organizerRefreshToken);
    final device = await _secureStore.read(SecureKey.authDeviceId);
    final token = await _secureStore.read(SecureKey.organizerAuthToken);
    if (refresh != null && device != null) {
      try {
        await _client.post(
          _baseUri.resolve('/auth/api/auth/logout-device'),
          headers: {
            'content-type': 'application/json',
            if (token != null) 'authorization': 'Bearer $token',
          },
          body: jsonEncode({'refreshToken': refresh, 'deviceId': device}),
        );
      } catch (_) {
        // Local token removal is authoritative for sign-out on this device.
      }
    }
    await _clearAuth();
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw RepositoryException(
        decoded['detail'] as String? ??
            decoded['message'] as String? ??
            'The server rejected the request (${response.statusCode}).',
        isNetwork: response.statusCode >= 500,
      );
    }
    return decoded;
  }

  Map<String, dynamic> _jwtClaims(String token) {
    final parts = token.split('.');
    if (parts.length != 3)
      throw const RepositoryException('Invalid session token.');
    return jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    ) as Map<String, dynamic>;
  }

  bool _isExpired(String token) {
    final exp = _jwtClaims(token)['exp'];
    return exp is! num ||
        DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000)
            .isBefore(DateTime.now().toUtc());
  }

  Organizer _requireCurrent() {
    final value = _current;
    if (value == null)
      throw const RepositoryException('Session expired. Sign in again.');
    return value;
  }

  Future<void> _storeProfile(Organizer organizer) => _secureStore.write(
        SecureKey.organizerProfile,
        jsonEncode({
          'id': organizer.id,
          'fullName': organizer.fullName,
          'email': organizer.email,
          'phone': organizer.phone,
          'emailVerified': organizer.emailVerified,
          'phoneVerified': organizer.phoneVerified,
        }),
      );

  Organizer _profileFromJson(Map<String, dynamic> value) => Organizer(
        id: value['id'] as String,
        fullName: value['fullName'] as String,
        email: value['email'] as String,
        phone: value['phone'] as String? ?? '',
        emailVerified: value['emailVerified'] as bool? ?? false,
        phoneVerified: value['phoneVerified'] as bool? ?? false,
      );

  Future<void> _clearAuth() async {
    _current = null;
    await Future.wait([
      _secureStore.delete(SecureKey.organizerAuthToken),
      _secureStore.delete(SecureKey.organizerRefreshToken),
      _secureStore.delete(SecureKey.authDeviceId),
      _secureStore.delete(SecureKey.organizerProfile),
    ]);
  }

  String _mask(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length < 4
        ? '•••'
        : '••• ••• ${digits.substring(digits.length - 4)}';
  }
}
