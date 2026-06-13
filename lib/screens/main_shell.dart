import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'notifications/notifications_screen.dart';
import 'home/home_screen.dart';
import 'diary/diary_screen.dart';
import 'exercise/exercise_screen.dart';
import 'statistic/statistic_screen.dart';
import 'history/history_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notif = context.read<NotificationProvider>();
      notif.syncSchedules();
      notif.refreshUnread();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Saat app kembali aktif: ambil ulang waktu reminder dari server
    // (mis. client mengubahnya lewat web) dan segarkan badge notifikasi.
    if (state == AppLifecycleState.resumed && mounted) {
      final notif = context.read<NotificationProvider>();
      notif.syncSchedules();
      notif.refreshUnread();
    }
  }

  static const _titles = ['Home', 'Diary', 'Exercise', 'Statistik', 'Riwayat'];

  final _diaryKey = GlobalKey<DiaryScreenState>();
  final _exerciseKey = GlobalKey<ExerciseScreenState>();
  final _statisticKey = GlobalKey<StatisticScreenState>();
  final _historyKey = GlobalKey<HistoryScreenState>();

  late final _screens = [
    const HomeScreen(),
    DiaryScreen(key: _diaryKey),
    ExerciseScreen(key: _exerciseKey),
    StatisticScreen(key: _statisticKey),
    HistoryScreen(key: _historyKey),
  ];

  /// Pindah tab + muat ulang data tab tujuan (karena IndexedStack menjaga
  /// state, screen tidak otomatis reload saat ditampilkan kembali).
  void _selectTab(int i) {
    setState(() => _index = i);
    switch (i) {
      case 1:
        _diaryKey.currentState?.reload();
        break;
      case 2:
        _exerciseKey.currentState?.reload();
        break;
      case 3:
        _statisticKey.currentState?.reload();
        break;
      case 4:
        _historyKey.currentState?.reload();
        break;
    }
  }

  Widget _buildAvatarImage(AuthProvider auth) {
    final serverPath = auth.client?['photo_url']?.toString() ?? auth.client?['photo_path']?.toString();
    if (serverPath != null && serverPath.isNotEmpty) {
      final url = serverPath.startsWith('http') ? serverPath : '${ApiConfig.storageUrl.replaceAll(RegExp(r'/$'), '')}/${serverPath.replaceFirst(RegExp(r'^/'), '')}';
      return ClipOval(
        child: Image.network(
          url,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildAvatarInitials(auth, 14),
        ),
      );
    }
    return _buildAvatarInitials(auth, 14);
  }

  Widget _buildAvatarInitials(AuthProvider auth, double fontSize) {
    return Text(
      auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
      style: TextStyle(
        color: CmColors.primaryGreen,
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 32),
            const SizedBox(width: 8),
            Text(
              _titles[_index],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Builder(
              builder: (context) {
                final unread = context.watch<NotificationProvider>().unreadCount;
                final icon = const Icon(Icons.notifications_none);
                if (unread <= 0) return icon;
                return Badge(
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  backgroundColor: CmColors.accentOrange,
                  child: icon,
                );
              },
            ),
            onPressed: () async {
              final notif = context.read<NotificationProvider>();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              // Segarkan badge setelah kembali (mis. user menandai dibaca)
              notif.refreshUnread();
            },
            tooltip: 'Notifikasi',
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            tooltip: 'Akun',
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: CmColors.accentOrange,
              child: _buildAvatarImage(auth),
            ),
            onSelected: (v) async {
              if (v == 'profile') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else if (v == 'logout') {
                await auth.logout();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: CmColors.accentOrange,
                      child: _buildAvatarImage(auth),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: CmColors.primaryGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            auth.user?['email']?.toString() ?? 'Lihat Profil',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: const [
                    Icon(Icons.person_outline, size: 20, color: CmColors.primaryGreen),
                    SizedBox(width: 12),
                    Text('Profil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 20, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(auth),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        backgroundColor: Colors.white,
        indicatorColor: CmColors.accentOrange.withValues(alpha: 0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Diary',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Exercise',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(AuthProvider auth) {
    final items = [
      ('Home', Icons.home_outlined, 0),
      ('Diary', Icons.menu_book_outlined, 1),
      ('Exercise', Icons.fitness_center_outlined, 2),
      ('Statistik', Icons.bar_chart_outlined, 3),
      ('Riwayat', Icons.history_outlined, 4),
    ];

    return Drawer(
      backgroundColor: CmColors.primaryGreen,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: CmColors.accentOrange,
                    child: Builder(builder: (context) {
                      final serverPath = auth.client?['photo_url']?.toString() ?? auth.client?['photo_path']?.toString();
                      if (serverPath != null && serverPath.isNotEmpty) {
                        final url = serverPath.startsWith('http') ? serverPath : '${ApiConfig.storageUrl.replaceAll(RegExp(r'/$'), '')}/${serverPath.replaceFirst(RegExp(r'^/'), '')}';
                        return ClipOval(
                          child: Image.network(
                            url,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildAvatarInitials(auth, 20),
                          ),
                        );
                      }
                      return _buildAvatarInitials(auth, 20);
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Lihat Profil',
                            style: TextStyle(color: CmColors.accentOrange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  ...items.map((item) {
                    final active = _index == item.$3;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        leading: Icon(
                          item.$2,
                          color: active ? const Color(0xFF1E3A16) : Colors.white70,
                        ),
                        title: Text(
                          item.$1,
                          style: TextStyle(
                            color: active ? const Color(0xFF1E3A16) : Colors.white,
                            fontWeight: active ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: active ? CmColors.accentOrange : null,
                        onTap: () {
                          _selectTab(item.$3);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),
                  const Divider(color: Colors.white24, height: 1),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      leading: const Icon(Icons.notifications_none, color: Colors.white70),
                      title: const Text('Notifikasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await auth.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
