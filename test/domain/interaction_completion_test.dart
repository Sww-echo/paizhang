import 'package:flutter_test/flutter_test.dart';

import 'package:paizhang/domain/models.dart';

void main() {
  test('关闭投票达到有效成员半数即可通过', () {
    expect(
      const RoomCloseVoteSummary(
        activeMemberCount: 2,
        approvedCount: 1,
      ).isPassed,
      isTrue,
    );
    expect(
      const RoomCloseVoteSummary(
        activeMemberCount: 2,
        approvedCount: 0,
      ).isPassed,
      isFalse,
    );
    expect(
      const RoomCloseVoteSummary(
        activeMemberCount: 3,
        approvedCount: 1,
      ).isPassed,
      isFalse,
    );
    expect(
      const RoomCloseVoteSummary(
        activeMemberCount: 3,
        approvedCount: 2,
      ).isPassed,
      isTrue,
    );
    expect(
      const RoomCloseVoteSummary(
        activeMemberCount: 4,
        approvedCount: 2,
      ).isPassed,
      isTrue,
    );
    expect(
      const RoomCloseVoteSummary(
        activeMemberCount: 4,
        approvedCount: 3,
      ).isPassed,
      isTrue,
    );
    expect(
      const RoomCloseVoteSummary(
        activeMemberCount: 0,
        approvedCount: 0,
      ).isPassed,
      isFalse,
    );
  });
}
