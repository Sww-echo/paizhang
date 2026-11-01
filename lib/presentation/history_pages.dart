import 'dart:async';

import 'package:flutter/material.dart';

import '../application/app_services.dart';
import '../domain/app_error.dart';
import '../domain/room_snapshot.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import 'design.dart';
import 'presentation_helpers.dart';
import 'room_widgets.dart';
import 'settlement_page.dart';

/// 个人历史：先加载房间摘要，展开后查看牌局，再按需加载明细。
///
/// 分页失败保留已加载内容，原位置重试，不清空整个列表。
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
    setState(() {
      _loading = true;
      _error = null;
    });
    final generation = _generation;
    try {
      final values = await widget.services.rooms!.listHistoryRooms(
        before: _history.isEmpty ? null : _history.last,
      );
      if (!mounted || generation != _generation) return;
      final ids = _history.map((room) => room.roomId).toSet();
      setState(() {
        _history.addAll(values.where((room) => !ids.contains(room.roomId)));
        _hasMore = values.length == 20;
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = mapAppError(error));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _generation++;
      _history.clear();
      _hasMore = true;
    });
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('历史记录')),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          if (_history.isEmpty && !_loading && _error == null)
            const PzBoard(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: PzHint('还没有历史牌局。参与房间并记录回合后，这里会显示摘要。'),
                ),
              ],
            ),
          for (final history in _history) ...[
            _HistoryRoomCard(
              key: ValueKey('${history.roomId}:$_generation'),
              services: widget.services,
              history: history,
            ),
            const SizedBox(height: 12),
          ],
          if (_error != null) ...[
            ErrorCard(message: _error!.message, onRetry: _loadMore),
            const SizedBox(height: 12),
          ],
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_hasMore && !_loading && _error == null)
            PzButton(
              label: '加载更多房间',
              tone: PzButtonTone.ghost,
              onPressed: _loadMore,
            ),
        ],
      ),
    ),
  );
}

class _HistoryRoomCard extends StatefulWidget {
  const _HistoryRoomCard({
    required this.services,
    required this.history,
    super.key,
  });
  final AppServices services;
  final HistoryRoomSummary history;
  @override
  State<_HistoryRoomCard> createState() => _HistoryRoomCardState();
}

class _HistoryRoomCardState extends State<_HistoryRoomCard> {
  final List<HistorySessionSummary> _sessions = [];
  bool _expanded = false;
  bool _loading = false;
  bool _hasMore = true;
  bool _opening = false;
  AppError? _error;

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await widget.services.rooms!.listHistorySessions(
        widget.history.roomId,
        before: _sessions.isEmpty ? null : _sessions.last,
      );
      if (!mounted) return;
      final ids = _sessions.map((value) => value.session.id).toSet();
      setState(() {
        _sessions.addAll(
          values.where((value) => !ids.contains(value.session.id)),
        );
        _hasMore = values.length == 20;
      });
    } catch (error) {
      if (mounted) setState(() => _error = mapAppError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded && _sessions.isEmpty) unawaited(_loadMore());
  }

  Future<void> _open(HistorySessionSummary value) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final snapshot = await widget.services.rooms!.getHistorySession(
        widget.history.roomId,
        value.session.id,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SettlementPage(
            room: snapshot.room,
            session: snapshot.sessions.single,
            rounds: snapshot.rounds,
            profiles: snapshot.profiles,
            currentUserId: widget.services.currentUser?.id,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mapAppError(error).message)));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.history;
    return PzBoard(
      title: history.name,
      pill: history.isCurrentMember
          ? null
          : const PzPill('已离开房间 · 历史只读', tone: PzPillTone.grey),
      onHeaderTap: _toggle,
      headerTrailing: Text(
        _expanded ? '收起' : '展开',
        style: TextStyle(fontSize: 12, color: PzColors.of(context).muted),
      ),
      children: [
        PzBoardRow(
          title: '${history.gameType} · ${history.sessionCount} 场牌局',
          detail: formatHistoryDate(history.lastActivityAt),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _toggle,
        ),
        if (_expanded) ...[
          if (_opening) const LinearProgressIndicator(minHeight: 2),
          if (_sessions.isEmpty && !_loading && _error == null)
            const Padding(
              padding: EdgeInsets.fromLTRB(13, 11, 13, 11),
              child: PzHint('还没有牌局记录'),
            ),
          for (final value in _sessions)
            PzBoardRow(
              title: value.session.name,
              detail:
                  '${value.roundCount} 局有效记录 · '
                  '${sessionStatusLabel(value.session.status)}',
              trailing: Text(
                formatHistoryDate(value.lastActivityAt),
                style: TextStyle(
                  fontSize: 12,
                  color: PzColors.of(context).muted,
                ),
              ),
              onTap: _opening ? null : () => _open(value),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(13),
              child: ErrorCard(message: _error!.message, onRetry: _loadMore),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_hasMore && !_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 8, 13, 11),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PzButton(
                  label: '加载更多牌局',
                  tone: PzButtonTone.ghost,
                  onPressed: _loadMore,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
