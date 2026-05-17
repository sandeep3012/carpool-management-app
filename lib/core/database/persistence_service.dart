import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Lightweight JSON file persistence service.
///
/// Each collection is stored as a single JSON file in the app's documents
/// directory: `carpool_<key>.json`.  Dart's single-threaded event loop
/// makes concurrent-write safety a non-issue.
///
/// Errors are swallowed and logged in debug mode so a corrupted file never
/// crashes the app — callers just get `null` on load and proceed to seed.
class PersistenceService {
  PersistenceService._();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Serialise [data] to `carpool_<key>.json`.
  static Future<void> saveJson(String key, dynamic data) async {
    try {
      final file = await _file(key);
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      if (kDebugMode) debugPrint('[Persistence] save($key) failed: $e');
    }
  }

  /// Load and decode `carpool_<key>.json`.
  /// Returns `null` when the file is absent, empty, or corrupt.
  static Future<dynamic> loadJson(String key) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      return jsonDecode(raw);
    } catch (e) {
      if (kDebugMode) debugPrint('[Persistence] load($key) failed: $e');
      return null;
    }
  }

  /// Delete a persisted file (useful for reset / test-only).
  static Future<void> deleteJson(String key) async {
    try {
      final file = await _file(key);
      if (await file.exists()) await file.delete();
    } catch (e) {
      if (kDebugMode) debugPrint('[Persistence] delete($key) failed: $e');
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static Future<File> _file(String key) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/carpool_$key.json');
  }
}
