import 'package:flutter/material.dart';
import '../models/ThemeProvider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt"),
        backgroundColor: const Color(0xFFA5E8FF),
        foregroundColor: const Color(0xFF1B4965),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text("Chế độ sáng / tối"),
            value: Provider.of<ThemeProvider>(context).isDark,
            onChanged: (_) {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("Giới thiệu ứng dụng"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Wave Music",
                applicationVersion: "1.0.0",
                applicationIcon: const Icon(Icons.music_note),
                children: [
                  const Text("Ứng dụng nghe nhạc miễn phí với chất lượng cao."),
                  const Text("\nPhát triển bởi Thông Tuấn Hiếu."),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
