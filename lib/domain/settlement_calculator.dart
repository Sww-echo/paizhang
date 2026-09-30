import 'models.dart';

class SettlementCalculator {
  const SettlementCalculator();

  SettlementResult calculate(Iterable<Round> rounds, ScoringMode mode) {
    final totals = <String, int>{};

    for (final round in rounds) {
      if (round.isDeleted) continue;
      for (final change in round.changes) {
        totals.update(
          change.playerId,
          (value) => value + change.value,
          ifAbsent: () => change.value,
        );
      }
    }

    final total = totals.values.fold<int>(0, (sum, value) => sum + value);
    final isBalanced = mode == ScoringMode.points || total == 0;
    if (!isBalanced) {
      return SettlementResult(
        totals: Map.unmodifiable(totals),
        transfers: const [],
        isBalanced: false,
        unbalancedAmount: total,
      );
    }

    final creditors = totals.entries
        .where((entry) => entry.value > 0)
        .map((entry) => _Balance(entry.key, entry.value))
        .toList();
    final debtors = totals.entries
        .where((entry) => entry.value < 0)
        .map((entry) => _Balance(entry.key, -entry.value))
        .toList();
    final transfers = <SettlementTransfer>[];
    var creditorIndex = 0;
    var debtorIndex = 0;

    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      final creditor = creditors[creditorIndex];
      final debtor = debtors[debtorIndex];
      final amount = creditor.amount < debtor.amount
          ? creditor.amount
          : debtor.amount;

      transfers.add(
        SettlementTransfer(
          fromPlayerId: debtor.playerId,
          toPlayerId: creditor.playerId,
          amount: amount,
        ),
      );

      creditor.amount -= amount;
      debtor.amount -= amount;
      if (creditor.amount == 0) creditorIndex++;
      if (debtor.amount == 0) debtorIndex++;
    }

    return SettlementResult(
      totals: Map.unmodifiable(totals),
      transfers: List.unmodifiable(transfers),
      isBalanced: true,
    );
  }
}

class _Balance {
  _Balance(this.playerId, this.amount);

  final String playerId;
  int amount;
}
