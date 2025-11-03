import 'package:flutter/material.dart';

// TODO: Redesign with Glassmorphism, Card Stack, Minimal Icons, and Gradient Banner
class RetroHawaiiSearchPage extends StatefulWidget {
  const RetroHawaiiSearchPage({super.key});

  @override
  State<RetroHawaiiSearchPage> createState() => _RetroHawaiiSearchPageState();
}

class _RetroHawaiiSearchPageState extends State<RetroHawaiiSearchPage> {
  final TextEditingController searchController = TextEditingController();
  String selectedFilter = 'All';
  bool isLoading = false;
  List<String> results = []; 
  List<String> history = ['summer breeze', 'aloha nights', 'ocean eyes'];

  void handleSearch(String query) async {
    setState(() {
      isLoading = true;
      results = [];
    });

    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      isLoading = false;
      results = List.generate(6, (i) => '$query result ${i + 1}');
      if (query.trim().isNotEmpty) {
        history.remove(query);
        history.insert(0, query);
        if (history.length > 10) history.removeLast();
      }
    });
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildResultList() {
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final item = results[index];
        return _buildResultCard(item);
      },
    );
  }

  Widget _buildResultCard(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _AppColors.seaBlue.shade400,
                    _AppColors.seaBlue.shade700,
                  ],
                ),
              ),
              child: const Icon(Icons.music_note, size: 30, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Opacity(opacity: 0.8, child: Text('Artist • Album', style: TextStyle(color: Colors.white70, fontSize: 12))),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white70),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: history
          .map((h) => ListTile(
                leading: const Icon(Icons.history, color: Colors.white70),
                title: Text(h, style: const TextStyle(color: Colors.white70)),
                onTap: () => handleSearch(h),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _AppColors.skyBlue.shade200,
                  _AppColors.seaBlue.shade500,
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  ClipPath(
                    clipper: WaveClipper(),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _AppColors.seaBlue.shade600,
                            _AppColors.seaBlue.shade800,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 28,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aloha', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text('Search', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  const SizedBox(height: 120),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: TextField(
                      controller: searchController,
                      onSubmitted: handleSearch,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search songs, artists, albums...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 10, right: 6),
                          child: Icon(Icons.search, color: Colors.white70),
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  setState(() => searchController.clear());
                                },
                                icon: const Icon(Icons.close, color: Colors.white70),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["All", "Songs", "Artists", "Albums"].map((type) {
                        final selected = selectedFilter == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type, style: TextStyle(color: selected ? Colors.white : Colors.white70)),
                            selected: selected,
                            selectedColor: _AppColors.coral,
                            backgroundColor: Colors.white.withOpacity(0.04),
                            onSelected: (_) => setState(() => selectedFilter = type),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? _buildShimmerLoading()
                        : results.isNotEmpty
                            ? _buildResultList()
                            : _buildHistoryList(),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    final firstControlPoint = Offset(size.width / 4, size.height);
    final firstEndPoint = Offset(size.width / 2, size.height - 40);
    final secondControlPoint = Offset(3 * size.width / 4, size.height - 80);
    final secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _AppColors {
  static const MaterialColor seaBlue = MaterialColor(_seaPrimary, <int, Color>{
    50: Color(0xFFE8F7FA),
    100: Color(0xFFCFF0F5),
    200: Color(0xFFA7E6EE),
    300: Color(0xFF7FDDEA),
    400: Color(0xFF56D4E6),
    500: Color(_seaPrimary),
    600: Color(0xFF0FA4CB),
    700: Color(0xFF0C93B8),
    800: Color(0xFF0A7FA3),
    900: Color(0xFF06607F),
  });
  static const int _seaPrimary = 0xFF13B6D9;

  static const MaterialColor skyBlue = MaterialColor(_skyPrimary, <int, Color>{
    50: Color(0xFFF3FBFD),
    100: Color(0xFFE6F6FB),
    200: Color(0xFFCCEFF7),
    300: Color(0xFFB3E8F2),
    400: Color(0xFF99E0EE),
    500: Color(_skyPrimary),
    600: Color(0xFF66D4E5),
    700: Color(0xFF4EC9E0),
    800: Color(0xFF3ABFD9),
    900: Color(0xFF1FAFCF),
  });
  static const int _skyPrimary = 0xFF8CE0F0;

  static const MaterialColor coral = MaterialColor(_coralPrimary, <int, Color>{
    50: Color(0xFFFFF1F0),
    100: Color(0xFFFFE6E5),
    200: Color(0xFFFFCFCB),
    300: Color(0xFFFFB6AE),
    400: Color(0xFFFF9A8E),
    500: Color(_coralPrimary),
    600: Color(0xFFFF6B61),
    700: Color(0xFFFF5E55),
    800: Color(0xFFFF524A),
    900: Color(0xFFFF3A35),
  });
  static const int _coralPrimary = 0xFFFF837C;
}
