import 'package:flutter/material.dart';
import '../models/ThemeProvider.dart';
import 'edit_account_info_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../screens/update_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                  child: const Icon(Icons.dark_mode_outlined, color: Colors.deepPurple),
                ),
                title: const Text("Light/Dark Mode"),
                value: Provider.of<ThemeProvider>(context).isDark,
                onChanged: (_) {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
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
                  child: const Icon(Icons.security_outlined, color: Colors.deepPurple),
                ),
                title: const Text(
                  "Security",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        MaterialPageRoute(builder: (context) => const UpdatePasswordScreen()),
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
                  child: const Icon(Icons.info_outline, color: Colors.deepPurple),
                ),
                title: const Text("Information"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
                title: const Text("Log out", style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xác nhận đăng xuất'),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    // Xóa token
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('token');

                    // Điều hướng về màn hình đăng nhập và xóa tất cả các màn hình trước đó
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    }
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
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.deepPurple.withOpacity(0.1),
        child: Icon(icon, color: Colors.deepPurple),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
