import 'package:flutter_test/flutter_test.dart';

import 'package:paizhang/application/paizhang_service.dart';
import 'package:paizhang/domain/models.dart';

void main() {
  late PaizhangService service;
  var id = 0;

  setUp(() {
    id = 0;
    service = PaizhangService(
      clock: () => DateTime(2026, 9, 30, 12),
      idFactory: (prefix) => '$prefix-${id++}',
    );
  });

  test('可以通过邀请码加入房间并完成积分牌局', () {
    final owner = service.registerUser(nickname: '张三');
    final player = service.registerUser(nickname: '李四');
    final room = service.createRoom(
      ownerId: owner.id,
      name: '周末牌局',
      gameType: '掼蛋',
      scoringMode: ScoringMode.points,
    );
    final invite = service.createInvite(roomId: room.id, kind: InviteKind.code);

    final joinedRoom = service.joinByCode(
      userId: player.id,
      code: service.inviteCode(invite),
    );
    expect(joinedRoom.members, hasLength(2));

    final game = service.startGame(
      roomId: room.id,
      actorId: owner.id,
      name: '第一场',
    );
    service.recordRound(
      sessionId: game.id,
      actorId: player.id,
      changes: [
        ScoreChange(playerId: owner.id, value: 20),
        ScoreChange(playerId: player.id, value: -20),
      ],
    );

    final result = service.settlement(game.id);
    expect(result.isBalanced, isTrue);
    expect(result.totals[owner.id], 20);
    expect(result.totals[player.id], -20);
    expect(result.transfers.single.fromPlayerId, player.id);
    expect(result.transfers.single.toPlayerId, owner.id);
    expect(result.transfers.single.amount, 20);
  });

  test('分享链接 Token 可以加入房间，撤销后不能继续加入', () {
    final owner = service.registerUser(nickname: '张三');
    final firstPlayer = service.registerUser(nickname: '李四');
    final secondPlayer = service.registerUser(nickname: '王五');
    final room = service.createRoom(
      ownerId: owner.id,
      name: '麻将局',
      gameType: '麻将',
      scoringMode: ScoringMode.money,
    );
    final invite = service.createInvite(
      roomId: room.id,
      kind: InviteKind.link,
      ttl: const Duration(minutes: 10),
    );

    expect(service.inviteLink(invite), contains(invite.token));
    expect(
      service.joinByToken(userId: firstPlayer.id, token: invite.token).members,
      hasLength(2),
    );

    service.revokeInvite(
      roomId: room.id,
      actorId: owner.id,
      token: invite.token,
    );
    expect(
      () => service.joinByToken(userId: secondPlayer.id, token: invite.token),
      throwsA(isA<PaizhangException>()),
    );
  });

  test('金额模式拒绝未平衡回合', () {
    final owner = service.registerUser(nickname: '张三');
    final player = service.registerUser(nickname: '李四');
    final room = service.createRoom(
      ownerId: owner.id,
      name: '现金局',
      gameType: '自定义',
      scoringMode: ScoringMode.money,
    );
    service.joinByToken(userId: player.id,
        token: service.createInvite(roomId: room.id, kind: InviteKind.link).token);
    final game = service.startGame(
      roomId: room.id,
      actorId: owner.id,
      name: '第一场',
    );

    expect(
      () => service.recordRound(
        sessionId: game.id,
        actorId: owner.id,
        changes: [
          ScoreChange(playerId: owner.id, value: 100),
          ScoreChange(playerId: player.id, value: -20),
        ],
      ),
      throwsA(isA<PaizhangException>().having(
          (error) => error.message, 'message', '金额模式下本局金额必须平衡')),
    );
  });

  test('仅房主录入模式会拒绝普通成员', () {
    final owner = service.registerUser(nickname: '张三');
    final player = service.registerUser(nickname: '李四');
    final room = service.createRoom(
      ownerId: owner.id,
      name: '周末局',
      gameType: '斗地主',
      scoringMode: ScoringMode.points,
    );
    service.joinByToken(
      userId: player.id,
      token: service.createInvite(roomId: room.id, kind: InviteKind.qr).token,
    );
    service.setInputPermission(
      roomId: room.id,
      actorId: owner.id,
      permission: InputPermission.ownerOnly,
    );
    final game = service.startGame(
      roomId: room.id,
      actorId: owner.id,
      name: '第一场',
    );

    expect(
      () => service.recordRound(
        sessionId: game.id,
        actorId: player.id,
        changes: [ScoreChange(playerId: owner.id, value: 1)],
      ),
      throwsA(isA<PaizhangException>()),
    );
  });

  test('可以修改和删除回合，结算会自动重算', () {
    final owner = service.registerUser(nickname: '张三');
    final player = service.registerUser(nickname: '李四');
    final room = service.createRoom(
      ownerId: owner.id,
      name: '周末局',
      gameType: '斗地主',
      scoringMode: ScoringMode.points,
    );
    service.joinByToken(
      userId: player.id,
      token: service.createInvite(roomId: room.id, kind: InviteKind.qr).token,
    );
    final game = service.startGame(
      roomId: room.id,
      actorId: owner.id,
      name: '第一场',
    );
    final round = service.recordRound(
      sessionId: game.id,
      actorId: owner.id,
      changes: [
        ScoreChange(playerId: owner.id, value: 10),
        ScoreChange(playerId: player.id, value: -10),
      ],
    );

    service.updateRound(
      sessionId: game.id,
      roundId: round.id,
      actorId: owner.id,
      changes: [
        ScoreChange(playerId: owner.id, value: 20),
        ScoreChange(playerId: player.id, value: -20),
      ],
    );
    expect(service.settlement(game.id).totals[owner.id], 20);

    service.deleteRound(
      sessionId: game.id,
      roundId: round.id,
      actorId: owner.id,
    );
    expect(service.settlement(game.id).totals, isEmpty);
  });

  test('普通成员可以退出，房主不能直接退出', () {
    final owner = service.registerUser(nickname: '张三');
    final player = service.registerUser(nickname: '李四');
    final room = service.createRoom(
      ownerId: owner.id,
      name: '周末局',
      gameType: '麻将',
      scoringMode: ScoringMode.points,
    );
    service.joinByToken(
      userId: player.id,
      token: service.createInvite(roomId: room.id, kind: InviteKind.qr).token,
    );

    final updated = service.leaveRoom(roomId: room.id, userId: player.id);
    expect(updated.memberOf(player.id), isNull);
    expect(
      () => service.leaveRoom(roomId: room.id, userId: owner.id),
      throwsA(isA<PaizhangException>()),
    );
  });
}
