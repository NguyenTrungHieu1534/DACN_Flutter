import 'package:flutter/material.dart';
import '../services/api_history.dart';
import '../models/history.dart';
import '../widgets/HistoryList.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  late Future<List<HistorySong>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _historyService.getHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.retroWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppColors.retroPrimary,
            foregroundColor: AppColors.retroWhite,
            title: const Text("Lịch sử nghe 🌺"),
            pinned: true,
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: FutureBuilder<List<HistorySong>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.retroAccent)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi tải dữ liệu 😢", style: TextStyle(color: AppColors.retroAccent),));
                }
                final history = snapshot.data ?? [];
                return HistoryList(
                  songs: history,
                  onTap: (song) {
                    // TODO: mở player hoặc detail
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
