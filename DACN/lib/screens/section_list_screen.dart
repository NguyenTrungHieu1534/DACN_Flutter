// import 'package:flutter/material.dart';
// import '../models/album.dart';
// import 'player_screen.dart';

// class SectionListScreen extends StatelessWidget {
//   SectionListScreen({Key? key, required this.title, required this.items})
//       : super(key: key) {
//     debugPrint(
//         'SectionListScreen constructed: title="$title", items=${items.length}');
//     debugPrint(StackTrace.current.toString());
//   }

//   final String title;
//   final List<Album> items;

//   @override
//   Widget build(BuildContext context) {
//     // Debug: also log builds
//     debugPrint('SectionListScreen.build: title="$title"');
//     return Scaffold(
//       appBar: AppBar(title: Text(title)),
//       body: GridView.builder(
//         padding: const EdgeInsets.all(12),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//           childAspectRatio: 0.8,
//         ),
//         itemCount: items.length,
//         itemBuilder: (context, index) {
//           final album = items[index];
//           final tag = 'section-${album.url}-$index';
//           return Material(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(14),
//             clipBehavior: Clip.antiAlias,
//             child: InkWell(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => PlayerScreen(

//                     ),
//                   ),
//                 );
//               },
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: Hero(
//                       tag: tag,
//                       child: Ink.image(
//                         image: NetworkImage(album.url),
//                         fit: BoxFit.cover,
//                         child: const SizedBox.expand(),
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
//                     child: Text(
//                       album.name,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(fontWeight: FontWeight.w700),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
//                     child: Text(
//                       album.artist,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style:
//                           const TextStyle(color: Colors.black54, fontSize: 12),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
