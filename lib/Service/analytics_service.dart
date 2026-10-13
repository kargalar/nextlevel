import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Privacy-friendly analytics stored only on the device.
///
/// The storage format is intentionally provider-agnostic so a consented remote
/// analytics adapter can be added later without coupling navigation to it.
class AnalyticsService {
  static const String _eventsKey = 'local_analytics_events_v1';
  static const int _maxEvents = 500;

  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  Future<void> _writeChain = Future<void>.value();

  void trackPageView(String pageName, {String source = 'navigation'}) {
    trackEvent(
      'page_view',
      parameters: {
        'page': pageName,
        'source': source,
      },
    );
  }

  void trackEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) {
    _writeChain = _writeChain.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final events = prefs.getStringList(_eventsKey) ?? <String>[];
      events.add(jsonEncode({
        'name': name,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'parameters': parameters,
      }));
      if (events.length > _maxEvents) {
        events.removeRange(0, events.length - _maxEvents);
      }
      await prefs.setStringList(_eventsKey, events);
    });
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    await _writeChain;
    final prefs = await SharedPreferences.getInstance();
    final rawEvents = prefs.getStringList(_eventsKey) ?? const <String>[];
    final events = <Map<String, dynamic>>[];
    for (final rawEvent in rawEvents) {
      try {
        final decoded = jsonDecode(rawEvent);
        if (decoded is Map<String, dynamic>) events.add(decoded);
      } on FormatException {
        // Ignore a single damaged local record instead of losing all analytics.
      }
    }
    return events;
  }

  Future<Map<String, int>> getPageViewCounts() async {
    final counts = <String, int>{};
    for (final event in await getEvents()) {
      if (event['name'] != 'page_view') continue;
      final parameters = event['parameters'];
      if (parameters is! Map) continue;
      final page = parameters['page']?.toString();
      if (page == null || page.isEmpty) continue;
      counts.update(page, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  Future<void> clear() async {
    await _writeChain;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_eventsKey);
  }
}
