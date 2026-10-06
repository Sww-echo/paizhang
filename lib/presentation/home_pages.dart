import '../infrastructure/backend/app_error_mapper.dart';

import 'package:flutter/material.dart';

import '../application/app_services.dart';
import '../domain/models.dart';

import 'dart:async';

import 'room_page.dart';
import 'history_pages.dart';
import 'profile_page.dart';
import 'sync_queue_page.dart';
import 'common_widgets.dart';
import 'room_widgets.dart';
import '../domain/invite_service.dart';

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
    final values = await showDialog<RoomFormValue>(
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
        MaterialPageRoute(
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
    final input = await showDialog<String>(
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
        MaterialPageRoute(
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
      MaterialPageRoute(
        builder: (_) => ConnectedHistoryPage(services: widget.services),
      ),
    );
  }

  Future<void> _openRoom(BuildContext context, Room room) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
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
          style: const TextStyle(fontSize: 15, color: Color(0xFF6B766F)),
        ),
        const SizedBox(height: 6),
        const Text(
          '今天也把账记清楚。',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ConnectedActionButton(
                icon: Icons.add_rounded,
                label: '创建房间',
                primary: true,
                onPressed: _busy ? null : () => _createRoom(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ConnectedActionButton(
                icon: Icons.login_rounded,
                label: '加入房间',
                onPressed: _busy ? null : () => _joinRoom(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            const Expanded(
              child: Text(
                '进行中的房间',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: widget.onOpenRooms,
              child: const Text('全部房间'),
            ),
          ],
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
              return const Card(
                elevation: 0,
                child: ListTile(
                  leading: Icon(Icons.groups_outlined),
                  title: Text('还没有进行中的房间'),
                  subtitle: Text('创建房间，或输入牌友的邀请码加入'),
                ),
              );
            }
            final visible = active.take(3).toList();
            return Column(
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  ConnectedRoomTile(
                    room: visible[index],
                    onTap: () => _openRoom(context, visible[index]),
                  ),
                  if (index != visible.length - 1) const SizedBox(height: 12),
                ],
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
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _openHistory(context),
          icon: const Icon(Icons.history_rounded),
          label: const Text('查看历史记录'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SyncQueuePage(services: widget.services),
            ),
          ),
          icon: const Icon(Icons.sync),
          label: const Text('同步记录'),
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
    final values = await showDialog<RoomFormValue>(
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
        MaterialPageRoute(
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
    final input = await showDialog<String>(
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
        MaterialPageRoute(
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
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
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
                const SizedBox(height: 24),
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
                    final rooms = snapshot.data ?? const <Room>[];
                    if (rooms.isEmpty) {
                      return const Card(
                        elevation: 0,
                        child: ListTile(
                          leading: Icon(Icons.groups_outlined),
                          title: Text('还没有房间'),
                          subtitle: Text('创建一个房间，开始记录牌局'),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (var index = 0; index < rooms.length; index++) ...[
                          ConnectedRoomTile(
                            room: rooms[index],
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ConnectedRoomPage(
                                    services: widget.services,
                                    room: rooms[index],
                                  ),
                                ),
                              );
                              if (mounted) setState(_reload);
                            },
                          ),
                          if (index != rooms.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
