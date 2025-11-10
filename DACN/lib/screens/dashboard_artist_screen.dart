import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ArtistDashboardScreen extends StatelessWidget {
  const ArtistDashboardScreen({super.key});

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
            _buildKpiSection(),
            const SizedBox(height: 24),
            _buildChartsAndAnalysis(),
            const SizedBox(height: 24),
            _buildContentManagement(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        },
        child: const Icon(Icons.upload),
      ),
    );
  }

  Widget _buildArtistHeader() {
    return const Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: NetworkImage('https://via.placeholder.com/150'),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Artist Name',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text('Welcome to your artist page.'),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatCard(label: 'Total Streams', value: '1.2M'),
        _StatCard(label: 'Followers', value: '45K'),
        _StatCard(label: 'Unread', value: '3'),
      ],
    );
  }

  Widget _buildKpiSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('At-a-Glance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _KpiCard(icon: Icons.music_note, label: "Today's Streams", value: '5.6K'),
            _KpiCard(icon: Icons.people, label: 'New Followers', value: '+250'),
            _KpiCard(icon: Icons.pending, label: 'Pending Songs', value: '2'),
          ],
        ),
      ],
    );
  }

  Widget _buildChartsAndAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildLineChart(),
        const SizedBox(height: 24),
        _buildTopSongs(),
        const SizedBox(height: 24),
        _buildGeoDistribution(),
      ],
    );
  }

  Widget _buildLineChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Streams This Month (+12% from last month)'),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 3),
                        FlSpot(2.6, 2),
                        FlSpot(4.9, 5),
                        FlSpot(6.8, 3.1),
                        FlSpot(8, 4),
                        FlSpot(9.5, 3),
                        FlSpot(11, 4),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top 5 Songs'),
            const SizedBox(height: 8),
            ...List.generate(5, (index) => _SongListItem(index: index)),
          ],
        ),
      ),
    );
  }

  Widget _buildGeoDistribution() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Listeners by Region'),
            SizedBox(height: 16),
            // Placeholder for map or pie chart
            Icon(Icons.map, size: 100, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildContentManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Content Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

  const _KpiCard({required this.icon, required this.label, required this.value});

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
  final int index;

  const _SongListItem({required this.index});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.music_video),
      title: Text('Song Title ${index + 1}'),
      trailing: Text('${100 - index * 10}K plays'),
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
