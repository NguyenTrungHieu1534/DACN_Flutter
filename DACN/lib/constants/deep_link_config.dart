const String deepLinkScheme = 'https';
const String deepLinkHost = 'nguyentrunghieu1534.github.io';
const String trackPathSegment = 'track';

Uri buildSongDeepLink(String songId) {
  final segments = <String>[];
  if (trackPathSegment.isNotEmpty) {
    segments.add(trackPathSegment);
  }
  segments.add(songId);

  return Uri(
    scheme: deepLinkScheme,
    host: deepLinkHost.isEmpty ? null : deepLinkHost,
    pathSegments: segments,
  );
}
