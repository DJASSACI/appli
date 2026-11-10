import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  List<dynamic> events = [];
  bool isLoading = true;
  String? error;
  int offset = 0;
  final int limit = 20;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    loadEvents(reset: true);
  }

  Future<void> loadEvents({bool reset = false}) async {
    if (reset) {
      offset = 0;
      events = [];
      hasMore = true;
    }
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final response = await ApiService.instance.get(
        '/api/admin/audit-log',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = response.data as Map<String, dynamic>;
      final newEvents = (data['events'] as List<dynamic>?) ?? [];
      setState(() {
        events.addAll(newEvents);
        offset += newEvents.length;
        hasMore = newEvents.length >= limit;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal d’audit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => loadEvents(reset: true),
          ),
        ],
      ),
      body: isLoading && events.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : error != null && events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Erreur: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => loadEvents(reset: true),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : events.isEmpty
                  ? const Center(child: Text('Aucun événement'))
                  : ListView.builder(
                      itemCount: events.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == events.length) {
                          if (isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: ElevatedButton(
                              onPressed: () => loadEvents(),
                              child: const Text('Charger plus'),
                            ),
                          );
                        }
                        final e = events[index] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(e['action']?.toString() ?? 'N/A'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${e['timestamp'] ?? ''}'),
                                Text('Acteur: ${e['actorId'] ?? 'N/A'}'),
                                Text('Résultat: ${e['result'] ?? 'N/A'}'),
                                if (e['targetType'] != null)
                                  Text('Cible: ${e['targetType']} ${e['targetId'] ?? ''}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
