const paizhangPublicBaseUrl = String.fromEnvironment(
  'PAIZHANG_PUBLIC_BASE_URL',
  defaultValue: 'https://paizhang.app',
);

class InviteService {
  const InviteService({this.webBaseUrl = paizhangPublicBaseUrl});

  final String webBaseUrl;

  String createShareLink(String token) =>
      'paizhang://room/join?token=${Uri.encodeComponent(token)}';

  String createWebLink(String token) {
    final baseUrl = webBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    return '$baseUrl/join/${Uri.encodeComponent(token)}';
  }

  String? extractToken(String value) {
    final input = value.trim();
    if (input.isEmpty) return null;
    final uri = Uri.tryParse(input);
    if (uri == null) return null;
    return _extractTokenFromUri(uri) ?? _extractTokenFromFragment(uri.fragment);
  }

  String? _extractTokenFromUri(Uri uri) {
    final queryToken = uri.queryParameters['token']?.trim();
    if (queryToken != null && queryToken.isNotEmpty) return queryToken;
    return _extractTokenFromSegments(uri.pathSegments);
  }

  String? _extractTokenFromFragment(String fragment) {
    if (fragment.isEmpty) return null;
    final normalized = fragment.startsWith('/') ? fragment : '/$fragment';
    final uri = Uri.tryParse('https://paizhang.local$normalized');
    return uri == null ? null : _extractTokenFromUri(uri);
  }

  String? _extractTokenFromSegments(List<String> segments) {
    final joinIndex = segments.indexOf('join');
    if (joinIndex == -1 || joinIndex == segments.length - 1) return null;
    final token = segments[joinIndex + 1].trim();
    if (token.isEmpty) return null;
    try {
      return Uri.decodeComponent(token);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  String normalizeCode(String code) => code.trim().toUpperCase();

  String createCode(String token) {
    final normalized = token
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (normalized.length >= 6) return normalized.substring(0, 6);
    return normalized.padRight(6, 'X');
  }
}
