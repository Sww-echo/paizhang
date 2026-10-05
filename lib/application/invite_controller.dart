import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../domain/app_error.dart';
import '../domain/invite_service.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import '../infrastructure/backend/app_error_mapper.dart';

class InviteController extends ChangeNotifier {
  InviteController({required this.repository, required this.onRoomReady});

  final RoomRepository repository;
  final void Function(Room room) onRoomReady;
  final _pending = Queue<String>();
  final _succeeded = <String>{};
  String? _actorId;
  String? _processing;
  String? _failed;
  Future<void>? _running;
  AppError? error;
  int _generation = 0;
  bool _disposed = false;

  bool get canRetry => _failed != null;

  void setActor(String? actorId) {
    if (_actorId == actorId) return;
    if (_actorId != null) {
      _pending.clear();
      _failed = null;
      error = null;
    }
    _actorId = actorId;
    _generation++;
    _succeeded.clear();
    _processing = null;
    unawaited(drain());
  }

  void receiveUri(Uri uri) {
    final token = const InviteService().extractToken(uri.toString());
    if (token != null) receiveToken(token);
  }

  void receiveToken(String token) {
    if (_disposed ||
        _succeeded.contains(token) ||
        _pending.contains(token) ||
        _processing == token) {
      return;
    }
    _pending.add(token);
    unawaited(drain());
  }

  Future<void> retryFailed() async {
    final token = _failed;
    if (token == null) return;
    _failed = null;
    error = null;
    receiveToken(token);
    await drain();
  }

  Future<void> drain() async {
    if (_disposed || _actorId == null) return;
    final active = _running;
    if (active != null) {
      await active;
      return;
    }
    final run = _consume(_generation);
    _running = run;
    try {
      await run;
    } finally {
      if (identical(_running, run)) _running = null;
      if (!_disposed && _actorId != null && _pending.isNotEmpty) {
        unawaited(drain());
      }
    }
  }

  Future<void> _consume(int generation) async {
    while (!_disposed && generation == _generation && _pending.isNotEmpty) {
      final token = _pending.removeFirst();
      _processing = token;
      try {
        final roomId = await repository.joinByToken(token);
        if (_disposed || generation != _generation) return;
        final room = await repository.getRoom(roomId);
        if (_disposed || generation != _generation) return;
        onRoomReady(room);
        _succeeded.add(token);
        if (_failed == token) _failed = null;
        error = null;
      } catch (failure) {
        if (_disposed || generation != _generation) return;
        _failed = token;
        error = mapAppError(failure);
      } finally {
        if (!_disposed && generation == _generation) {
          _processing = null;
          notifyListeners();
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _pending.clear();
    super.dispose();
  }
}
