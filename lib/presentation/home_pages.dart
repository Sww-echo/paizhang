import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../application/app_services.dart';
import '../domain/invite_service.dart';
import '../domain/models.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import 'common_widgets.dart';
import 'design.dart';
import 'history_pages.dart';
import 'profile_page.dart';
import 'room_page.dart';
import 'room_widgets.dart';
import 'sync_queue_page.dart';

class ConnectedHomeShell extends StatefulWidget {
  const ConnectedHomeShell({required this.services, super.key});

  final AppServices services;

  @override
  State<ConnectedHomeShell> createState() => _ConnectedHomeShellState();
}

class _ConnectedHomeShellState extends State<ConnectedHomeShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.services.loadRooms().catchError((Object _) => const <Room>[]),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ConnectedHomePage(
        services: widget.services,
        onMessage: _showMessage,
        onRoomsChanged: widget.services.invalidateRooms,
        onOpenRooms: () => setState(() => _selectedIndex = 1),
      ),
      ConnectedRoomsPage(services: widget.services, onMessage: _showMessage),
      ConnectedProfilePage(services: widget.services),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          unawaited(HapticFeedback.selectionClick());
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: '牌局',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: '房间',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class ConnectedHomePage extends StatefulWidget {
  const ConnectedHomePage({
    required this.services,
    required this.onMessage,
    required this.onRoomsChanged,
    required this.onOpenRooms,
    super.key,
  });

  final AppServices services;
  final ValueChanged<String> onMessage;
  final VoidCallback onRoomsChanged;
  final VoidCallback onOpenRooms;

  @override
  State<ConnectedHomePage> createState() => _ConnectedHomePageState();
}

class _ConnectedHomePageState extends State<ConnectedHomePage> {
  bool _busy = false;

  Future<void> _createRoom(BuildContext context) async {
    if (_busy) return;
    final values = await showPzDialog<RoomFormValue>(
      context: context,
      builder: (context) => const RoomFormDialog(),
    );
    if (values == null || !context.mounted) return;
    setState(() => _busy = true);
    try {
      final room = await widget.services.rooms!.createRoom(
        name: values.name,
        gameType: values.gameType,
        scoringMode: values.scoringMode,
      );
      widget.onRoomsChanged();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        PzPageRoute(
          builder: (_) =>
              ConnectedRoomPage(services: widget.services, room: room),
        ),
      );
    } catch (error) {
      widget.onMessage(mapAppError(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom(BuildContext context) async {
    if (_busy) return;
    final input = await showPzDialog<String>(
      context: context,
      builder: (context) => const JoinRoomDialog(),
    );
    if (input == null || !context.mounted) return;
    setState(() => _busy = true);
    try {
      final token = const InviteService().extractToken(input);
      final roomId = token == null
          ? await widget.services.rooms!.joinByCode(input)
          : await widget.services.rooms!.joinByToken(token);
      final room = await widget.services.rooms!.getRoom(roomId);
      widget.onRoomsChanged();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        PzPageRoute(
          builder: (_) =>
              ConnectedRoomPage(services: widget.services, room: room),
        ),
      );
    } catch (error) {
      widget.onMessage(mapAppError(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openHistory(BuildContext context) async {
    await Navigator.of(context).push(
      PzPageRoute(
        builder: (_) => ConnectedHistoryPage(services: widget.services),
      ),
    );
  }

  Future<void> _openRoom(BuildContext context, Room room) async {
    await Navigator.of(context).push(
      PzPageRoute(
        builder: (_) =>
            ConnectedRoomPage(services: widget.services, room: room),
      ),
    );
    widget.onRoomsChanged();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.services.currentUser;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      children: [
        Text(
          '晚上好，${user?.nickname ?? '牌友'}',
          style: TextStyle(
            fontSize: 26,
            height: 1.27,
            fontWeight: FontWeight.w800,
            color: PzColors.of(context).fg,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '今天也把账记清楚。',
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: PzColors.of(context).muted,
          ),
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConnectedActionButton(
              icon: Icons.add_rounded,
              label: '创建房间',
              primary: true,
              onPressed: _busy ? null : () => _createRoom(context),
            ),
            const SizedBox(height: 12),
            ConnectedActionButton(
              icon: Icons.login_rounded,
              label: '加入房间',
              onPressed: _busy ? null : () => _joinRoom(context),
            ),
          ],
        ),
        const SizedBox(height: 24),
        PzSectionTitle(
          '进行中的房间',
          action: TextButton(
            onPressed: widget.onOpenRooms,
            child: const Text('全部房间'),
          ),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: Listenable.merge([
            widget.services.roomList,
            widget.services.roomsLoading,
            widget.services.roomsError,
          ]),
          builder: (context, _) {
            final rooms = widget.services.roomList.value;
            final active = rooms.where((room) => !room.isClosed).toList();
            if (active.isEmpty) {
              if (widget.services.roomsLoading.value) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final error = widget.services.roomsError.value;
              if (error != null) {
                return ErrorCard(
                  message: error.message,
                  onRetry: widget.onRoomsChanged,
                );
              }
              return const PzBoard(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '还没有进行中的房间',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        PzHint('创建房间，或输入牌友的邀请码加入'),
                      ],
                    ),
                  ),
                ],
              );
            }
            final visible = active.take(3).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PzBoard(
                  children: [
                    for (var index = 0; index < visible.length; index++)
                      PzReveal(
                        delay: Duration(milliseconds: index * 40),
                        child: ConnectedRoomTile(
                          room: visible[index],
                          onTap: () => _openRoom(context, visible[index]),
                        ),
                      ),
                  ],
                ),
                if (active.length > visible.length)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: widget.onOpenRooms,
                      child: Text('还有 ${active.length - visible.length} 个房间'),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        PzBoard(
          title: '记录与恢复',
          children: [
            PzBoardRow(
              title: '历史记录',
              detail: '过往房间、牌局与结算',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openHistory(context),
            ),
            PzBoardRow(
              title: '同步记录',
              detail: '待同步、冲突与未提交的本地修改',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                PzPageRoute(
                  builder: (_) => SyncQueuePage(services: widget.services),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ConnectedRoomsPage extends StatefulWidget {
  const ConnectedRoomsPage({
    required this.services,
    required this.onMessage,
    super.key,
  });

  final AppServices services;
  final ValueChanged<String> onMessage;

  @override
  State<ConnectedRoomsPage> createState() => _ConnectedRoomsPageState();
}

class _ConnectedRoomsPageState extends State<ConnectedRoomsPage> {
  late Future<List<Room>> _roomsFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _roomsFuture = widget.services.loadRooms();
    widget.services.roomList.addListener(_onRoomsChanged);
  }

  void _onRoomsChanged() {
    if (mounted) {
      setState(() {
        _roomsFuture = Future.value(widget.services.roomList.value);
      });
    }
  }

  @override
  void dispose() {
    widget.services.roomList.removeListener(_onRoomsChanged);
    super.dispose();
  }

  void _reload() {
    _roomsFuture = widget.services.loadRooms(force: true);
  }

  Future<void> _refresh() async {
    setState(_reload);
    try {
      await _roomsFuture;
    } catch (error) {
      if (mounted) widget.onMessage(mapAppError(error).message);
    }
  }

  Future<void> _createRoom() async {
    if (_busy) return;
    final values = await showPzDialog<RoomFormValue>(
      context: context,
      builder: (context) => const RoomFormDialog(),
    );
    if (values == null) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final room = await widget.services.rooms!.createRoom(
        name: values.name,
        gameType: values.gameType,
        scoringMode: values.scoringMode,
      );
      if (!mounted) return;
      setState(_reload);
      await Navigator.of(context).push(
        PzPageRoute(
          builder: (_) =>
              ConnectedRoomPage(services: widget.services, room: room),
        ),
      );
      if (mounted) setState(_reload);
    } catch (error) {
      widget.onMessage(mapAppError(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom() async {
    if (_busy) return;
    final input = await showPzDialog<String>(
      context: context,
      builder: (context) => const JoinRoomDialog(),
    );
    if (input == null) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final token = const InviteService().extractToken(input);
      final roomId = token == null
          ? await widget.services.rooms!.joinByCode(input)
          : await widget.services.rooms!.joinByToken(token);
      final room = await widget.services.rooms!.getRoom(roomId);
      if (!mounted) return;
      setState(_reload);
      await Navigator.of(context).push(
        PzPageRoute(
          builder: (_) =>
              ConnectedRoomPage(services: widget.services, room: room),
        ),
      );
      if (mounted) setState(_reload);
    } catch (error) {
      widget.onMessage(mapAppError(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            title: Text(
              '我的房间',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: ConnectedActionButton(
                        icon: Icons.add_rounded,
                        label: '创建房间',
                        primary: true,
                        onPressed: _busy ? null : _createRoom,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ConnectedActionButton(
                        icon: Icons.login_rounded,
                        label: '加入房间',
                        onPressed: _busy ? null : _joinRoom,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Room>>(
                  future: _roomsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return ErrorCard(
                        message: mapAppError(snapshot.error!).message,
                        onRetry: () => setState(_reload),
                      );
                    }
                    final rooms = [...(snapshot.data ?? const <Room>[])]
                      ..sort((left, right) {
                        final byClosed = (left.isClosed ? 1 : 0).compareTo(
                          right.isClosed ? 1 : 0,
                        );
                        if (byClosed != 0) return byClosed;
                        return right.createdAt.compareTo(left.createdAt);
                      });
                    if (rooms.isEmpty) {
                      return const PzBoard(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '还没有房间',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                PzHint('创建一个房间，开始记录牌局'),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return PzBoard(
                      children: [
                        for (var index = 0; index < rooms.length; index++)
                          PzReveal(
                            delay: Duration(
                              milliseconds: (index.clamp(0, 5)) * 40,
                            ),
                            child: ConnectedRoomTile(
                              room: rooms[index],
                              onTap: () async {
                                await Navigator.of(context).push(
                                  PzPageRoute(
                                    builder: (_) => ConnectedRoomPage(
                                      services: widget.services,
                                      room: rooms[index],
                                    ),
                                  ),
                                );
                                if (mounted) setState(_reload);
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                const PzHint('离开或被移除后的房间放入历史记录，当前列表不混入。'),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
