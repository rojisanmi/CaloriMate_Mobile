import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.get('/client/notifications');
      final data = response.data;
      if (data is Map<String, dynamic> && data['notifications'] is List) {
        _notifications = List<Map<String, dynamic>>.from(data['notifications']);
      } else {
        _notifications = [];
      }
    } catch (e) {
      _error = 'Gagal memuat notifikasi. Coba lagi nanti.';
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead([int? id]) async {
    try {
      await ApiClient.instance.post(
        '/client/notifications/read',
        data: id != null ? {'id': id} : null,
      );

      if (!mounted) return;

      setState(() {
        if (id == null) {
          _notifications = _notifications
              .map((item) => {...item, 'is_read': true})
              .toList();
        } else {
          _notifications = _notifications
              .map((item) => item['id'] == id ? {...item, 'is_read': true} : item)
              .toList();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(id == null ? 'Semua notifikasi ditandai sudah dibaca.' : 'Notifikasi ditandai sudah dibaca.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui status notifikasi.')), 
      );
    }
  }

  int get _unreadCount =>
      _notifications.where((notif) => notif['is_read'] == false).length;

  Widget _buildNotificationItem(Map<String, dynamic> notif) {
    final isRead = notif['is_read'] == true;
    final type = notif['type'] as String? ?? 'info';
    final icon = type == 'warning'
        ? Icons.warning_amber_rounded
        : type == 'exercise'
            ? Icons.fitness_center
            : type == 'food'
                ? Icons.restaurant
                : Icons.notifications;

    return Card(
      margin: EdgeInsets.zero,
      color: isRead ? Colors.white : const Color(0xFFFFF7E4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: isRead ? Colors.grey.shade200 : const Color(0xFFF5A623),
          child: Icon(icon, color: isRead ? Colors.black54 : Colors.white),
        ),
        title: Text(
          notif['title']?.toString() ?? 'Notifikasi',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notif['message']?.toString() ?? ''),
            const SizedBox(height: 6),
            Text(
              notif['time']?.toString() ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
        trailing: isRead
            ? null
            : TextButton(
                onPressed: () => _markAsRead(notif['id'] as int),
                child: const Text('Tandai dibaca'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () => _markAsRead(),
              child: const Text('Tandai semua'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                  )
                : _notifications.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: Column(
                              children: const [
                                Icon(Icons.notifications_off, size: 64, color: Colors.black26),
                                SizedBox(height: 16),
                                Text('Belum ada notifikasi baru.', style: TextStyle(fontSize: 16, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => _buildNotificationItem(_notifications[index]),
                      ),
      ),
    );
  }
}
