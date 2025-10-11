import 'package:flutter/material.dart';
import 'shimmer_widgets.dart';

/// Demo widget to showcase different shimmer loading states
/// This can be used for testing or as a reference
class ShimmerDemo extends StatelessWidget {
  const ShimmerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shimmer Loading Demo'),
        backgroundColor: const Color(0xFF70C1B3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Album Card Shimmer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ShimmerWidgets.albumCardShimmer(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Song Card Shimmer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ShimmerWidgets.songCardShimmer(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Trending Album Shimmer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 280),
                  child: ShimmerWidgets.trendingAlbumCardShimmer(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'List Item Shimmer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (index) => ShimmerWidgets.listItemShimmer()),
          ],
        ),
      ),
    );
  }
}
