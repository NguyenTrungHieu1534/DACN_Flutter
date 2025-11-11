import 'package:flutter/material.dart';
import '../models/ThemeProvider.dart';
import 'edit_account_info_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../screens/update_password_screen.dart';
import '../services/api_user.dart';
import  '../screens/dashboard_artist_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _isPrivate;
  bool _savingPrivacy = false;
  String? _userId;
  bool _privacyLocalMode = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
  }

  Future<void> _loadPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    final decoded = JwtDecoder.decode(token);
    final userId = decoded['_id']?.toString();
    if (userId == null) return;
    _userId = userId;
    final service = UserService();
    final current = await service.getPrivacy(userId);
    if (!mounted) return;
    if (current == null) {
      // Backend không hỗ trợ → dùng lưu cục bộ
      final local = prefs.getBool('privacy_local') ?? false;
      setState(() {
        _privacyLocalMode = true;
        _isPrivate = local;
      });
    } else {
      setState(() {
        _privacyLocalMode = false;
        _isPrivate = current;
      });
    }
  }

  Future<void> _togglePrivacy(bool value) async {
    if (_userId == null) return;
    if (_privacyLocalMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_local', value);
      if (!mounted) return;
      setState(() {
        _isPrivate = value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu cục bộ trạng thái Private')),
      );
      return;
    }

    setState(() {
      _savingPrivacy = true;
      _isPrivate = value;
    });
    final service = UserService();
    final res = await service.updatePrivacy(userId: _userId!, isPrivate: value);
    if (!mounted) return;
    setState(() {
      _savingPrivacy = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message']?.toString() ?? 'Đã cập nhật')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Setting"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "Appearance"),
            _buildCard(
              context,
              child: SwitchListTile(
                secondary: CircleAvatar(
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  child: const Icon(Icons.dark_mode_outlined,
                      color: Colors.deepPurple),
                ),
                title: const Text("Light/Dark Mode"),
                value: Provider.of<ThemeProvider>(context).isDark,
                onChanged: (_) {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme();
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, "Privacy"),
            _buildCard(
              context,
              child: SwitchListTile(
                secondary: CircleAvatar(
                  backgroundColor: Colors.teal.withOpacity(0.1),
                  child: const Icon(Icons.lock_outline, color: Colors.teal),
                ),
                title: const Text("Private profile"),
                subtitle: Text(
                  _savingPrivacy
                      ? "Saving..."
                      : "Make your profile private to others"
                ),
                value: _isPrivate ?? false,
                onChanged: (val) async {
                  final previous = _isPrivate ?? false;
                  await _togglePrivacy(val);
                  // Revert switch if failed
                  if (!mounted) return;
                  // We infer failure if still saving false and message shown as failure;
                  // simpler: reload from server to reflect truth
                  await _loadPrivacy();
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, "Account & Security"),
            _buildCard(
              context,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  child: const Icon(Icons.security_outlined,
                      color: Colors.deepPurple),
                ),
                title: const Text(
                  "Security",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildSettingItem(
                    context,
                    icon: Icons.badge_outlined,
                    title: "Username & Email",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const EditAccountInfoScreen()),
                      );
                    },
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.password_outlined,
                    title: "Change Password",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UpdatePasswordScreen()),
                      );
                    },
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.email_outlined,
                    title: "Verify Email",
                    onTap: () async {
                      final msg = await UserService.sendVerifyEmail();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );
                    },
                  ),
                ],
              ),
            ),
            _buildCard(
              context,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  child: const Icon(Icons.person_outline,
                      color: Colors.deepPurple),
                ),
                title: const Text(
                  "Account",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildSettingItem(
                    context,
                    icon: Icons.music_note_outlined,
                    title: "Upgrade To Artist ",
                    onTap: () async {
                      try {
                        final data = await UserService.askForArtist();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(data ?? 'Có lỗi xảy ra')),
                        );
                      } catch (err) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Có lỗi xảy ra: $err')),
                        );
                      }
                    },
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    title: "Dashboard Artist ",
                    onTap: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ArtistDashboardScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, "About App"),
            _buildCard(
              context,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                  child:
                      const Icon(Icons.info_outline, color: Colors.deepPurple),
                ),
                title: const Text("Information"),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: "Wave Music",
                    applicationVersion: "1.0.0",
                    applicationIcon: const Icon(Icons.music_note),
                    children: const [
                      Text("Ứng dụng nghe nhạc miễn phí với chất lượng cao."),
                      Text("\nPhát triển bởi Thông Tuấn Hiếu."),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildCard(
              context,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  child: const Icon(Icons.logout, color: Colors.red),
                ),
                title:
                    const Text("Log out", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xác nhận đăng xuất'),
                      content:
                          const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await UserService.logout();
                    Navigator.of(context, rootNavigator: true)
                        .pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                },
                hoverColor: Colors.red.withOpacity(0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildSettingItem(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.deepPurple.withOpacity(0.1),
        child: Icon(icon, color: Colors.deepPurple),
      ),
      title: Text(title),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
      hoverColor: Colors.deepPurple.withOpacity(0.05),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
