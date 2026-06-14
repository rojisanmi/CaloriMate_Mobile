import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import 'trainer_dashboard_screen.dart';
import 'trainer_foods_screen.dart';
import 'trainer_programs_screen.dart';
import '../profile/trainer_profile_screen.dart';

class TrainerShell extends StatefulWidget {
  const TrainerShell({super.key});

  @override
  State<TrainerShell> createState() => _TrainerShellState();
}

class _TrainerShellState extends State<TrainerShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _titles = ['Dashboard', 'Kelola Makanan', 'Kelola Latihan', 'Profil Trainer'];

  final _screens = const [
    TrainerDashboardScreen(),
    TrainerFoodsScreen(),
    TrainerProgramsScreen(),
    TrainerProfileScreen(),
  ];

  Widget _buildAvatarImage(AuthProvider auth) {
    final serverPath = auth.trainer?['photo_url']?.toString() ?? auth.trainer?['photo_path']?.toString();
    if (serverPath != null && serverPath.isNotEmpty) {
      final url = serverPath.startsWith('http') ? serverPath : '${ApiConfig.storageUrl.replaceAll(RegExp(r'/$'), '')}/${serverPath.replaceFirst(RegExp(r'^/'), '')}';
      return ClipOval(
        child: Image.network(
          url,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildAvatarInitials(auth, 14),
        ),
      );
    }
    return _buildAvatarInitials(auth, 14);
  }

  Widget _buildAvatarInitials(AuthProvider auth, double fontSize) {
    return Text(
      auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'T',
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
                setState(() => _index = 3);
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
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: CmColors.accentOrange.withValues(alpha: 0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Makanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Latihan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(AuthProvider auth) {
    final items = [
      ('Dashboard', Icons.dashboard_outlined, 0),
      ('Makanan', Icons.restaurant_menu_outlined, 1),
      ('Latihan', Icons.fitness_center_outlined, 2),
      ('Profil', Icons.person_outline, 3),
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
                      final serverPath = auth.trainer?['photo_url']?.toString() ?? auth.trainer?['photo_path']?.toString();
                      if (serverPath != null && serverPath.isNotEmpty) {
                        final url = serverPath.startsWith('http') ? serverPath : '${ApiConfig.storageUrl.replaceAll(RegExp(r'/$'), '')}/${serverPath.replaceFirst(RegExp(r'^/'), '')}';
                        return ClipOval(
                          child: Image.network(
                            url,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildAvatarInitials(auth, 20),
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
                        const SizedBox(height: 2),
                        Text(
                          auth.user?['username']?.toString() ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
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
                            setState(() => _index = 3);
                            Navigator.pop(context);
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
                          setState(() => _index = item.$3);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
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
