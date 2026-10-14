import 'package:flutter/services.dart';

class LockScreenChannel {
  static const _channel = MethodChannel('com.rutadefe/lock_ads');

  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    await _channel.invokeMethod('setEnabled', {'enabled': enabled});
  }

  Future<void> updateCatalog(String catalogPath) async {
    await _channel.invokeMethod('updateCatalog', {'path': catalogPath});
  }

  Future<void> applyCurrent() async {
    await _channel.invokeMethod('applyCurrent');
  }

  Future<void> applyNext() async {
    await _channel.invokeMethod('applyNext');
  }
}
