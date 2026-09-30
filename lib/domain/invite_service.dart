class InviteService {
  const InviteService();

  String createShareLink(String token) => 'paizhang://room/join?token=$token';

  String createWebLink(String token) => 'https://paizhang.app/join/$token';

  String normalizeCode(String code) => code.trim().toUpperCase();

  String createCode(String token) {
    final normalized = token
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (normalized.length >= 6) return normalized.substring(0, 6);
    return normalized.padRight(6, 'X');
  }
}
