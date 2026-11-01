import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/domain/settlement_calculator.dart';

const _sessionId = 'session-1';
const _actor = 'user-1';
final _createdAt = DateTime.utc(2026, 10, 4, 19);

Round _round(int number, Map<String, int> scores, {bool deleted = false}) =>
    Round(
      id: 'round-$number',
      sessionId: _sessionId,
      number: number,
      changes: [
        for (final entry in scores.entries)
          ScoreChange(playerId: entry.key, value: entry.value),
      ],
      createdBy: _actor,
      createdAt: _createdAt,
      deletedAt: deleted ? _createdAt : null,
    );

Map<String, int> _edges(SettlementResult result) => {
  for (final transfer in result.transfers)
    '${transfer.fromPlayerId}->${transfer.toPlayerId}': transfer.amount,
};

void main() {
  const calculator = SettlementCalculator();

  test('金额模式不平账时返回 isBalanced=false、空转账与差额', () {
    final result = calculator.calculate([
      _round(1, {'a': 100, 'b': -60, 'c': -30}),
    ], ScoringMode.money);

    expect(result.isBalanced, isFalse);
    expect(result.transfers, isEmpty);
    expect(result.unbalancedAmount, 10);
    expect(result.totals, {'a': 100, 'b': -60, 'c': -30});
  });

  test('同一玩家跨回合分数累加后才参与结算', () {
    final result = calculator.calculate([
      _round(1, {'a': 30, 'b': -30}),
      _round(2, {'a': -10, 'b': 10}),
      _round(3, {'a': 5, 'b': -5}),
    ], ScoringMode.money);

    expect(result.totals, {'a': 25, 'b': -25});
    expect(result.isBalanced, isTrue);
    expect(result.unbalancedAmount, 0);
    expect(_edges(result), {'b->a': 25});
  });

  test('单个债主对单个债主的多笔配对各自独立成条', () {
    final result = calculator.calculate([
      _round(1, {'a': 90, 'b': -50, 'c': -30, 'd': -10}),
    ], ScoringMode.money);

    expect(result.isBalanced, isTrue);
    expect(result.transfers, hasLength(3));
    expect(_edges(result), {'b->a': 50, 'c->a': 30, 'd->a': 10});
    expect(result.transfers.fold<int>(0, (sum, t) => sum + t.amount), 90);
  });

  test('两个债主与两个债权人按贪心顺序拆分转账', () {
    final result = calculator.calculate([
      _round(1, {'a': 70, 'b': 30, 'c': -60, 'd': -40}),
    ], ScoringMode.money);

    expect(result.isBalanced, isTrue);
    expect(result.transfers, hasLength(3));
    expect(_edges(result), {'c->a': 60, 'd->a': 10, 'd->b': 30});
    expect(
      result.transfers.fold<int>(0, (sum, t) => sum + t.amount),
      100,
      reason: '转账总额必须等于债权总额，否则结算页会少收钱',
    );
  });

  test('已撤销的回合不计入总分也不产生转账', () {
    final result = calculator.calculate([
      _round(1, {'a': 30, 'b': -30}),
      _round(2, {'a': 999, 'b': -999}, deleted: true),
    ], ScoringMode.money);

    expect(result.totals, {'a': 30, 'b': -30});
    expect(result.isBalanced, isTrue);
    expect(_edges(result), {'b->a': 30});
  });

  test('没有任何回合时返回空结算且标记已平衡', () {
    final result = calculator.calculate(const [], ScoringMode.money);

    expect(result.totals, isEmpty);
    expect(result.transfers, isEmpty);
    expect(result.isBalanced, isTrue);
    expect(result.unbalancedAmount, 0);
  });

  // 现状记录：积分模式下剩余差额被静默丢弃，仍对外宣称已平衡。
  // 这条断言是「已知语义缺口」的看门狗，产品一旦决定显式化残差，它会先失败。
  test('积分模式总分不为零时仍标记已平衡，残差不进 unbalancedAmount', () {
    final result = calculator.calculate([
      _round(1, {'a': 12, 'b': -5}),
    ], ScoringMode.points);

    expect(result.isBalanced, isTrue);
    expect(result.unbalancedAmount, 0);
    expect(result.totals, {'a': 12, 'b': -5});
    expect(_edges(result), {'b->a': 5});
  });
}
