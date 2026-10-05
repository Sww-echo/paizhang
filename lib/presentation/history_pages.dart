import 'dart:async';
import '../domain/app_error.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import 'package:flutter/material.dart';
import '../application/app_services.dart';
import '../domain/models.dart';
import '../domain/room_snapshot.dart';
import 'settlement_page.dart';
import 'room_widgets.dart';
import 'presentation_helpers.dart';

class ConnectedHistoryPage extends StatefulWidget {
  const ConnectedHistoryPage({required this.services, super.key});

  final AppServices services;

  @override
  State<ConnectedHistoryPage> createState() => _ConnectedHistoryPageState();
}
class _ConnectedHistoryPageState extends State<ConnectedHistoryPage> {
  final List<HistoryRoomSummary> _history = [];
  bool _loading = false;
  bool _hasMore = true;
  AppError? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadMore());
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() { _loading = true; _error = null; });
    final generation = _generation;
    try {
      final values = await widget.services.rooms!.listHistoryRooms(
          before: _history.isEmpty ? null : _history.last);
      if (!mounted || generation != _generation) return;
      final ids = _history.map((room) => room.roomId).toSet();
      setState(() {
        _history.addAll(values.where((room) => !ids.contains(room.roomId)));
        _hasMore = values.length == 20;
      });
    } catch (error) {
      if (mounted && generation == _generation) setState(() => _error = mapAppError(error));
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() { _generation++; _history.clear(); _hasMore = true; });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('历史记录')),
    body: RefreshIndicator(onRefresh: _refresh, child: ListView(
      physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20),
      children: [
        if (_history.isEmpty && !_loading && _error == null)
          const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('还没有历史牌局'))),
        for (final history in _history)
          _HistoryRoomCard(key: ValueKey('${history.roomId}:$_generation'),
              services: widget.services, history: history),
        if (_error != null) ErrorCard(message: _error!.message, onRetry: _loadMore),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_hasMore && !_loading && _error == null)
          TextButton(onPressed: _loadMore, child: const Text('加载更多房间')),
      ],
    )),
  );
}

class _HistoryRoomCard extends StatefulWidget {
  const _HistoryRoomCard({required this.services, required this.history, super.key});
  final AppServices services;
  final HistoryRoomSummary history;
  @override
  State<_HistoryRoomCard> createState() => _HistoryRoomCardState();
}

class _HistoryRoomCardState extends State<_HistoryRoomCard> {
  final List<HistorySessionSummary> _sessions = [];
  bool _loading = false;
  bool _hasMore = true;
  bool _opening = false;
  AppError? _error;

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() { _loading = true; _error = null; });
    try {
      final values = await widget.services.rooms!.listHistorySessions(widget.history.roomId,
          before: _sessions.isEmpty ? null : _sessions.last);
      if (!mounted) return;
      final ids = _sessions.map((value) => value.session.id).toSet();
      setState(() {
        _sessions.addAll(values.where((value) => !ids.contains(value.session.id)));
        _hasMore = values.length == 20;
      });
    } catch (error) {
      if (mounted) setState(() => _error = mapAppError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(HistorySessionSummary value) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final snapshot = await widget.services.rooms!.getHistorySession(widget.history.roomId, value.session.id);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettlementPage(
        room: snapshot.room, session: snapshot.sessions.single,
        rounds: snapshot.rounds, profiles: snapshot.profiles)));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapAppError(error).message)));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(elevation: 0, child: ExpansionTile(
    leading: const CircleAvatar(child: Icon(Icons.groups_rounded)),
    title: Text(widget.history.name),
    subtitle: Text('${widget.history.sessionCount} 场牌局 · ${widget.history.isCurrentMember ? '当前成员' : '已离开/被移除'}'),
    onExpansionChanged: (expanded) { if (expanded && _sessions.isEmpty) unawaited(_loadMore()); },
    children: [
      if (_opening) const LinearProgressIndicator(),
      for (final value in _sessions)
        ListTile(title: Text(value.session.name),
          subtitle: Text('${value.roundCount} 局有效记录 · ${sessionStatusLabel(value.session.status)}'),
          trailing: Text(formatHistoryDate(value.lastActivityAt)),
          onTap: _opening ? null : () => _open(value)),
      if (_error != null) ErrorCard(message: _error!.message, onRetry: _loadMore),
      if (_loading) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
      if (_hasMore && !_loading && _error == null)
        TextButton(onPressed: _loadMore, child: const Text('加载更多牌局')),
    ],
  ));
}

class RoomHistoryPage extends StatelessWidget {
  const RoomHistoryPage({super.key, required this.snapshot});

  final RemoteRoomSnapshot snapshot;

  Future<void> _openSettlement(
    BuildContext context,
    GameSession session,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettlementPage(
          room: snapshot.room,
          session: session,
          rounds: snapshot.rounds
              .where((round) => round.sessionId == session.id)
              .toList(),
          profiles: snapshot.profiles,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = [
      ...snapshot.sessions,
    ]..sort((left, right) => sessionDate(right).compareTo(sessionDate(left)));
    return Scaffold(
      appBar: AppBar(title: Text('${snapshot.room.name} · 历史')),
      body: sessions.isEmpty
          ? const Center(child: Text('还没有历史牌局'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final rounds =
                    snapshot.rounds
                        .where((round) => round.sessionId == session.id)
                        .toList()
                      ..sort(
                        (left, right) => right.number.compareTo(left.number),
                      );
                return Card(
                  elevation: 0,
                  child: ExpansionTile(
                    title: Text(session.name),
                    subtitle: Text(
                      '${activeRoundCount(snapshot, session)} 局有效记录 · ${sessionStatusLabel(session.status)}',
                    ),
                    trailing: Text(formatHistoryDate(sessionDate(session))),
                    children: [
                      if (rounds.isEmpty)
                        const ListTile(title: Text('还没有回合记录'))
                      else
                        for (final round in rounds)
                          ListTile(
                            leading: CircleAvatar(
                              child: Text('${round.number}'),
                            ),
                            title: Text(
                              round.isDeleted
                                  ? '第 ${round.number} 局（已撤销）'
                                  : round.changes
                                        .map(
                                          (change) =>
                                              '${profileName(change.playerId, snapshot.profiles)} ${change.value > 0 ? '+' : ''}${change.value}',
                                        )
                                        .join('，'),
                            ),
                            subtitle: round.note == null || round.note!.isEmpty
                                ? null
                                : Text(round.note!),
                          ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: TextButton.icon(
                            onPressed: () => _openSettlement(context, session),
                            icon: const Icon(Icons.emoji_events_rounded),
                            label: const Text('查看结算'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
