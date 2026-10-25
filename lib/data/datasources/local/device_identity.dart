import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'secure_storage.dart';

/// Collects and caches a stable per-install device id (UUID v4) plus a
/// human-readable device info string. These are sent with mobile logins so the
/// backend can enforce single-device binding and record which device signed in
/// (see docs/mobile-app-plan.md §4.1.1).
///
/// device_id is a *soft* client-reported identifier: it is stable per install
/// (regenerated only on reinstall / data clear), not a security boundary by
/// itself. The real control is the backend's "one active mobile session +
/// panel-revocable" policy.
class DeviceIdentity {
  final SecureStorage _storage;
  DeviceIdentity(this._storage);

  String? _deviceId;
  String? _deviceInfo;

  /// Stable per-install device id. Generated once on first use and persisted.
  Future<String> deviceId() async {
    if (_deviceId != null) return _deviceId!;
    var id = await _storage.getDeviceId();
    if (id == null || id.isEmpty) {
      id = _generateUuidV4();
      await _storage.saveDeviceId(id);
    }
    _deviceId = id;
    return id;
  }

  /// Human-readable device info, e.g. "iPhone 15 / iOS 17.2".
  Future<String> deviceInfo() async {
    if (_deviceInfo != null) return _deviceInfo!;
    _deviceInfo = await _collectDeviceInfo();
    return _deviceInfo!;
  }

  Future<String> _collectDeviceInfo() async {
    try {
      final info = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final d = await info.androidInfo;
        return '${d.model} / Android ${d.version.release}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final d = await info.iosInfo;
        return '${d.utsname.machine} / iOS ${d.systemVersion}';
      }
    } catch (_) {
      // fall through to a generic label
    }
    return defaultTargetPlatform.name;
  }

  static String _generateUuidV4() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    values[6] = (values[6] & 0x0F) | 0x40; // version 4
    values[8] = (values[8] & 0x3F) | 0x80; // RFC 4122 variant
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
