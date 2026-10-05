import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/app_error.dart';
import '../../domain/models.dart' show PaizhangException;
import 'transport_error_stub.dart'
    if (dart.library.io) 'transport_error_io.dart';

AppError mapAppError(Object error) {
  if (error is AppError) return error;
  if (error is TimeoutException ||
      error is ClientException ||
      isTransportError(error) ||
      error is AuthRetryableFetchException) {
    return const AppError(
      AppErrorKind.network,
      '网络暂不可用，操作会在恢复后重试',
      code: 'network',
    );
  }
  if (error is PaizhangException) {
    return AppError(AppErrorKind.validation, error.message);
  }
  final String? code;
  final String? message;
  if (error is PostgrestException) {
    code = error.code;
    message = error.message;
  } else if (error is AuthException) {
    code = error.code;
    message = error.message;
  } else if (error is StorageException) {
    code = error.statusCode;
    message = error.message;
  } else {
    return const AppError(AppErrorKind.unknown, '操作未完成，请稍后重试', code: 'unknown');
  }
  const businessErrors = <String, (AppErrorKind, String)>{
    'not_authenticated': (AppErrorKind.unauthenticated, '请先登录'),
    'room_member_required': (
      AppErrorKind.forbidden,
      '你已不再是房间成员，可返回历史记录查看已授权内容',
    ),
    'room_owner_required': (AppErrorKind.forbidden, '只有房主可以执行此操作'),
    'room_not_found': (AppErrorKind.notFound, '房间不存在或已无法访问'),
    'round_not_found': (AppErrorKind.notFound, '该回合已不存在，请刷新'),
    'room_closed': (AppErrorKind.forbidden, '房间已关闭，当前只能查看历史和结算'),
    'round_write_forbidden': (AppErrorKind.forbidden, '当前牌局或权限已变化，不能提交这条记录'),
    'round_edit_forbidden': (AppErrorKind.forbidden, '只有回合创建者可以修改记录'),
    'player_not_in_room': (AppErrorKind.validation, '只能为有效房间成员记录新的分数'),
    'version_conflict': (AppErrorKind.conflict, '记录已更新，请查看最新值并重新确认修改'),
    'version_required': (AppErrorKind.conflict, '缺少记录版本，请刷新后重试'),
    'client_upgrade_required': (AppErrorKind.validation, '请更新客户端后再提交'),
    'money_round_unbalanced': (AppErrorKind.validation, '金额模式每局必须平账'),
    'active_session_exists': (AppErrorKind.validation, '仍有进行中的牌局，请先结束所有牌局'),
    'vote_expired': (AppErrorKind.validation, '本轮关闭投票已失效，请重新发起'),
    'another_close_vote_pending': (AppErrorKind.validation, '已有另一种关闭方式的投票进行中'),
    'vote_not_started': (AppErrorKind.validation, '请先发起关闭投票'),
    'only_draft_can_delete': (AppErrorKind.validation, '只有草稿牌局可以删除'),
    'invalid_session_transition': (AppErrorKind.validation, '当前牌局状态不允许这个操作'),
    'session_finished': (AppErrorKind.validation, '牌局已结束，请先重新打开'),
    'operation_conflict': (AppErrorKind.conflict, '同步操作标识冲突，请重新确认记录'),
  };
  final known = businessErrors[message] ?? businessErrors[code];
  if (known != null) {
    return AppError(
      known.$1,
      known.$2,
      code: businessErrors.containsKey(message) ? message : code,
    );
  }
  if (code == '40001') {
    return const AppError(
      AppErrorKind.conflict,
      '记录已更新，请刷新并重新确认',
      code: 'version_conflict',
    );
  }
  if (code == '42501' || code == '403') {
    return const AppError(
      AppErrorKind.forbidden,
      '当前账号没有执行此操作的权限',
      code: 'forbidden',
    );
  }
  if (code == 'PGRST116' || code == '404') {
    return const AppError(
      AppErrorKind.notFound,
      '内容不存在或无法访问',
      code: 'not_found',
    );
  }
  if (code == 'PGRST301' || code == '401') {
    return const AppError(
      AppErrorKind.unauthenticated,
      '登录已失效，请重新登录',
      code: 'unauthenticated',
    );
  }
  if (code == '502' || code == '503' || code == '504') {
    return const AppError(
      AppErrorKind.network,
      '服务暂不可用，稍后自动重试',
      code: 'server_unavailable',
    );
  }
  return const AppError(AppErrorKind.unknown, '操作未完成，请稍后重试', code: 'unknown');
}

Future<T> guardRemote<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (error) {
    throw mapAppError(error);
  }
}
