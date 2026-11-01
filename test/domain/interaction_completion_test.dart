import 'package:flutter_test/flutter_test.dart';

import 'package:paizhang/domain/models.dart';

void main() {
  test('关闭投票按半数门槛计算剩余票数', () {
    for (final values in [
      (members: 1, approved: 0, required: 1, remaining: 1),
      (members: 2, approved: 1, required: 1, remaining: 0),
      (members: 3, approved: 1, required: 2, remaining: 1),
      (members: 4, approved: 1, required: 2, remaining: 1),
      (members: 5, approved: 4, required: 3, remaining: 0),
    ]) {
      final vote = RoomCloseVoteSummary(
        activeMemberCount: values.members,
        approvedCount: values.approved,
      );
      expect(vote.requiredApprovals, values.required);
      expect(vote.remainingApprovals, values.remaining);
    }
  });

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
