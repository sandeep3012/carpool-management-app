import 'package:flutter/foundation.dart';

/// App bootstrap orchestration
class AppBootstrap {
  static Future<void> initialize() async {
    try {
      // Initialize services in order
      await _initializeServices();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Bootstrap error: $e\n$stackTrace');
      }
      rethrow;
    }
  }

  static Future<void> _initializeServices() async {
    // Logger service is already a provider, no special init needed
    // Other services can be added here as needed
  }
}
