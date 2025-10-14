import 'package:flutter/material.dart';
import '../services/api_history.dart';
import '../models/history.dart';
import '../widgets/HistoryList.dart';

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
      appBar: AppBar(
        title: Text("Lịch sử nghe 🌺"),
        centerTitle: true,
        backgroundColor: Color(0xFF70A0C1), // xanh skyblue retro
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF70A0C1),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: FutureBuilder<List<HistorySong>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Lỗi tải dữ liệu 😢"));
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
    );
  }
}
