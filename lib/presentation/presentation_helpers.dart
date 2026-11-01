import '../domain/models.dart';

DateTime sessionDate(GameSession session) {
  return session.finishedAt ?? session.startedAt ?? session.createdAt;
}

String sessionStatusLabel(GameSessionStatus status) {
  return switch (status) {
    GameSessionStatus.draft => '未开始',
    GameSessionStatus.active => '进行中',
    GameSessionStatus.finished => '已结束',
  };
}

String roomStatusLabel(RoomStatus status) {
  return switch (status) {
    RoomStatus.waiting => '等待中',
    RoomStatus.active => '进行中',
    RoomStatus.finished => '已结束',
    RoomStatus.archived => '已归档',
    RoomStatus.dissolved => '已解散',
  };
}

String formatHistoryDate(DateTime value) {
  final date = value.toLocal();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}-$month-$day $hour:$minute';
}

String scoreUnitLabel(ScoringMode mode) {
  return mode == ScoringMode.money ? '金额' : '积分';
}

String profileName(String userId, Map<String, User> profiles) {
  return profiles[userId]?.nickname ?? '玩家 ${shortId(userId)}';
}

String initialFor(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
}

String shortId(String value) {
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}

/// Upper bound mirrored from the design math (JS `LIMIT`).
const pzScoreLimit = 2147483647;

/// Parses an optional-sign integer within the allowed range.
///
/// Mirrors the proposal's `integer()` helper: a leading `+` is accepted,
/// the U+2212 minus is normalized, and [positive] requires a value > 0.
int? pzParseScoreInteger(String raw, {bool positive = false}) {
  final text = raw.trim().replaceAll('\u2212', '-');
  if (!RegExp(r'^[+-]?\d+$').hasMatch(text)) return null;
  final value = int.tryParse(text);
  if (value == null || value < -2147483648 || value > pzScoreLimit) {
    return null;
  }
  if (positive && value <= 0) return null;
  return value;
}

/// Splits [total] into [count] parts, remainder one unit each to the first
/// members in fixed join order (proposal's `split()`).
List<int> pzSplitAmount(int total, int count) {
  if (count <= 0) {
    throw ArgumentError.value(count, 'count', '必须为正整数');
  }
  final sign = total.sign;
  final absolute = total.abs();
  final base = absolute ~/ count;
  final extra = absolute % count;
  return List.generate(
    count,
    (index) => sign * (base + (index < extra ? 1 : 0)),
  );
}

/// Field label for the scoring unit: 金额（元） / 积分.
String pzAmountLabel(ScoringMode mode) =>
    mode == ScoringMode.money ? '金额（元）' : '积分';

/// Value suffix used after signed numbers: 元 / 分.
String pzScoreUnit(ScoringMode mode) => mode == ScoringMode.money ? '元' : '分';
