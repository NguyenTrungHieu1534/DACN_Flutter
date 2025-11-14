import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_history.dart';
import '../services/api_songs.dart';
import '../services/api_follow.dart';

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});

  @override
  State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
}

class _ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
  Map<String, dynamic>? decodedToken;
  final HistoryService historyService = HistoryService();
  final SongService songService = SongService();
  final FollowService followService = FollowService();
  late int totalHistory = 0;
  late int totalFollow = 0;
  late var listSongs = [];
  @override
  void initState() {
    _userIn4();
    super.initState();
  }

  void _userIn4() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    // if(token != null) return;
    decodedToken = JwtDecoder.decode(token!);
    totalHistory = await historyService.fetchTotalHistory(decodedToken!['_id']);
    Text('Total History: ${totalHistory.toString()}');
     totalHistory = totalHistory * 500;
    totalFollow =
        await followService.fetchTotalFollow(decodedToken!['_id'].toString());
    // print('Total follow: $totalFollow');
    totalFollow = totalFollow * 50;
    listSongs = await historyService.fetchHistory(decodedToken!['username']);
    debugPrint('List songs: $listSongs');
    setState(() {});
  }

  String formatNumber(int number) {
    if (number >= 1000000) {
      return "${(number / 1000000).toStringAsFixed(1)}M";
    } else if (number >= 1000) {
      return "${(number / 1000).toStringAsFixed(1)}K";
    } else {
      return number.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildArtistHeader(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildChartsAndAnalysis(),
            const SizedBox(height: 24),
            _buildContentManagement(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.upload),
      ),
    );
  }

  Widget _buildArtistHeader() {
    final username = decodedToken?['username'].toString() ?? 'Artist Name';
    final avatarUrl = decodedToken?['ava']?.toString() ?? '';
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: NetworkImage('$avatarUrl'),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              username,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Welcome to your artist page.'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatCard(label: 'Total Streams', value: formatNumber(totalHistory)),
        _StatCard(label: 'Followers', value: formatNumber(totalFollow)),
        _StatCard(label: 'Unread', value: '3'),
      ],
    );
  }
  Widget _buildChartsAndAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildLineChart(),
        const SizedBox(height: 24),
        _buildTopSongs(),
        const SizedBox(height: 24),
      ],
    );
  }

  List<FlSpot> _generateSpots(List<dynamic> historyData) {
    if (historyData.isEmpty) {
      return [];
    }

    Map<int, int> dailyCounts = {};
    for (var record in historyData) {
      try {
        DateTime lastPlayed = DateTime.parse(record['lastPlayed']);
        int day = lastPlayed.day;
        int count = record['count'] ?? 1;
        dailyCounts.update(day, (value) => value + count,
            ifAbsent: () => count);
      } catch (e) {
        debugPrint('Error parsing date: ${record['lastPlayed']}');
      }
    }

    List<FlSpot> spots = dailyCounts.entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
    }).toList();

    spots.sort((a, b) => a.x.compareTo(b.x));

    return spots;
  }

  Widget _buildLineChart() {
    List<FlSpot> spots = _generateSpots(listSongs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Streams This Month'),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: listSongs.isEmpty
                  ? const Center(child: Text('No streaming data available.'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 10,
                                  child: Text(value.toInt().toString()),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() == 0) return Container();
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 10,
                                  child: Text(value.toInt().toString()),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 5,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSongs() {
    final sortedSongs = List.from(listSongs);
    sortedSongs.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top 3 Songs'),
            const SizedBox(height: 8),
            if (sortedSongs.isEmpty)
              const Center(child: Text('No song data available.'))
            else
              ...sortedSongs
                  .take(3)
                  .map((song) => _SongListItem(song: song))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Content Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ...List.generate(3, (index) => _UploadedSongItem(index: index)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _KpiCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SongListItem extends StatelessWidget {
  final dynamic song;

  const _SongListItem({required this.song});

  @override
  Widget build(BuildContext context) {
    final title = song['title'] ?? 'Unknown Title';
    final count = song['count']?.toString() ?? '0';

    return ListTile(
      leading: const Icon(Icons.music_video),
      title: Text(title),
      trailing: Text('$count plays'),
    );
  }
}

class _UploadedSongItem extends StatelessWidget {
  final int index;
  final statuses = ['Published', 'Pending', 'Rejected'];

  _UploadedSongItem({required this.index});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Uploaded Song ${index + 1}'),
      subtitle: Text(statuses[index % statuses.length]),
      trailing: const Text('1.2K plays'),
    );
  }
}
