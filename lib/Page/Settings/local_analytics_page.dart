import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/analytics_service.dart';

class LocalAnalyticsPage extends StatefulWidget {
  const LocalAnalyticsPage({super.key});

  @override
  State<LocalAnalyticsPage> createState() => _LocalAnalyticsPageState();
}

class _LocalAnalyticsPageState extends State<LocalAnalyticsPage> {
  late Future<Map<String, int>> _counts;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _counts = AnalyticsService().getPageViewCounts();
  }

  Future<void> _clear() async {
    await AnalyticsService().clear();
    if (!mounted) return;
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Analytics'),
        actions: [
          IconButton(
            tooltip: 'Clear analytics',
            onPressed: _clear,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _counts,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data!.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final total = entries.fold<int>(0, (sum, item) => sum + item.value);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.panelBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'These $total page views stay on this device. No analytics '
                  'data is sent to the developer or to an analytics provider.',
                ),
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: Text('No page views recorded yet.')),
                )
              else
                for (final entry in entries)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.web_asset_rounded),
                      title: Text(entry.key),
                      trailing: Text(
                        entry.value.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
