import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../application/app_services.dart';
import '../infrastructure/backend/app_error_mapper.dart';
import 'avatar_widgets.dart';
import 'design.dart';
import 'history_pages.dart';
import 'sync_queue_page.dart';

/// 我的：资料、记录与恢复分组明确。
///
/// 登录邮箱作为账号标识，不因免验证码注册显示「已验证」。
/// 退出登录不是删除数据，有未同步记录时先说明保留位置。
class ConnectedProfilePage extends StatefulWidget {
  const ConnectedProfilePage({required this.services, super.key});

  final AppServices services;

  @override
  State<ConnectedProfilePage> createState() => _ConnectedProfilePageState();
}

class _ConnectedProfilePageState extends State<ConnectedProfilePage> {
  late String _nickname;
  String? _avatarKey;
  String? _avatarUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = widget.services.currentUser;
    _nickname = user?.nickname.trim() ?? '';
    _avatarKey = user?.avatarKey;
    _avatarUrl = user?.avatarUrl;
  }

  Future<void> _openEditProfile() async {
    final user = widget.services.currentUser;
    if (user == null || _busy) return;
    setState(() => _busy = true);
    try {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EditProfilePage(
            services: widget.services,
            initialNickname: _nickname.isEmpty ? user.nickname : _nickname,
            initialAvatarKey: _avatarKey,
            initialAvatarUrl: _avatarUrl,
          ),
        ),
      );
      if (!mounted) return;
      final updated = widget.services.currentUser;
      if (updated?.id != user.id) return;
      setState(() {
        _nickname = updated?.nickname.trim() ?? _nickname;
        _avatarKey = updated?.avatarKey;
        _avatarUrl = updated?.avatarUrl;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final actorId = widget.services.currentUser?.id;
      var pending = 0;
      var failures = 0;
      if (actorId != null) {
        final entries = await widget.services.database.unresolvedOperations(
          actorId: actorId,
        );
        pending = entries
            .where(
              (entry) =>
                  entry.status == 'pending' || entry.status == 'retrying',
            )
            .length;
        failures = entries
            .where(
              (entry) =>
                  entry.status == 'rejected' || entry.status == 'conflict',
            )
            .length;
      }
      if (!mounted) return;
      final hasUnsynced = pending > 0 || failures > 0;
      final confirmed = await showPzDialog<bool>(
        context: context,
        builder: (dialogContext) => PzDialogShell(
          title: '退出登录',
          actions: [
            if (hasUnsynced)
              PzButton(
                label: '查看同步记录',
                tone: PzButtonTone.secondary,
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SyncQueuePage(services: widget.services),
                    ),
                  );
                },
              ),
            PzButton(
              label: '取消',
              tone: PzButtonTone.secondary,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            PzButton(
              label: '退出登录',
              tone: hasUnsynced ? PzButtonTone.secondary : PzButtonTone.primary,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
          children: [
            if (hasUnsynced)
              PzNotice(
                title: '还有 $pending 条待同步、$failures 条需处理',
                message:
                    '这些记录保留在本机。用原账号重新登录后，可继续同步或处理；'
                    '其他账号不会看到或提交它们。',
              ),
            const PzHint('退出登录不会删除账号，也不会清除未同步输入。'),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        try {
          await widget.services.auth!.signOut();
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(mapAppError(error).message)));
          }
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.services.currentUser;
    final displayName = _nickname.isEmpty
        ? user?.email ?? user?.phone ?? '牌友'
        : _nickname;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        const Text(
          '我的',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        PzBoard(
          title: '我的资料',
          children: [
            PzBoardRow(
              avatar: UserAvatar(
                name: displayName,
                avatarKey: _avatarKey,
                avatarUrl: _avatarUrl,
                radius: 20,
              ),
              title: displayName,
              detail: user?.email ?? user?.phone ?? '',
              trailing: TextButton(
                onPressed: _busy ? null : _openEditProfile,
                child: const Text('编辑'),
              ),
              onTap: _busy ? null : _openEditProfile,
            ),
          ],
        ),
        const SizedBox(height: 12),
        PzBoard(
          title: '记录与恢复',
          children: [
            PzBoardRow(
              title: '历史记录',
              detail: '过往房间、牌局与结算',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ConnectedHistoryPage(services: widget.services),
                ),
              ),
            ),
            PzBoardRow(
              title: '同步记录',
              detail: '待同步、冲突与未提交的本地修改',
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SyncQueuePage(services: widget.services),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PzButton(
          label: '退出登录',
          tone: PzButtonTone.ghost,
          icon: Icons.logout_rounded,
          onPressed: _busy ? null : _signOut,
        ),
      ],
    );
  }
}

/// 编辑资料：选择头像与修改昵称先更新本地预览，点保存后才提交。
///
/// 昵称与头像分开提交，结果分别说明；取消不调用修改接口。
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.services,
    required this.initialNickname,
    this.initialAvatarKey,
    this.initialAvatarUrl,
  });

  final AppServices services;
  final String initialNickname;
  final String? initialAvatarKey;
  final String? initialAvatarUrl;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nicknameController = TextEditingController(
    text: widget.initialNickname,
  );
  late String? _avatarKey = widget.initialAvatarKey;
  late String? _avatarUrl = widget.initialAvatarUrl;
  late String _savedNickname = widget.initialNickname;
  late String? _savedAvatarKey = widget.initialAvatarKey;
  late String? _savedAvatarUrl = widget.initialAvatarUrl;
  bool _savedAny = false;
  XFile? _pickedImage;
  bool _avatarRemoved = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _hasAvatar =>
      _pickedImage != null || _avatarKey != null || _avatarUrl != null;

  Future<void> _pickImage() async {
    if (_busy) return;
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image == null || !mounted) return;
      setState(() {
        _pickedImage = image;
        _avatarRemoved = false;
        _message = null;
      });
    } catch (error) {
      if (mounted) setState(() => _message = mapAppError(error).message);
    }
  }

  Future<void> _selectPreset() async {
    if (_busy) return;
    final avatarKey = await showPzDialog<String>(
      context: context,
      builder: (context) => const AvatarPresetDialog(),
    );
    if (avatarKey == null || !mounted) return;
    setState(() {
      _avatarKey = avatarKey;
      _avatarUrl = null;
      _pickedImage = null;
      _avatarRemoved = false;
      _message = null;
    });
  }

  void _removeAvatar() {
    if (_busy) return;
    setState(() {
      _avatarKey = null;
      _avatarUrl = null;
      _pickedImage = null;
      _avatarRemoved = true;
      _message = null;
    });
  }

  String _extensionFor(XFile image) {
    var extension = image.name.split('.').last.toLowerCase();
    if (extension == 'jpeg') extension = 'jpg';
    if (!{'jpg', 'png', 'webp'}.contains(extension)) {
      extension = switch (image.mimeType) {
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => extension,
      };
    }
    return extension;
  }

  /// 先保存昵称，再保存头像；任一失败保留草稿并说明实际结果。
  Future<void> _save() async {
    if (_busy) return;
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      setState(() => _message = '昵称不能为空');
      return;
    }
    if (nickname.length > 40) {
      setState(() => _message = '昵称不能超过 40 个字符');
      return;
    }
    final nicknameChanged = nickname != _savedNickname;
    final avatarChanged =
        _pickedImage != null ||
        _avatarRemoved ||
        _avatarKey != _savedAvatarKey ||
        _avatarUrl != _savedAvatarUrl;
    if (!nicknameChanged && !avatarChanged) {
      Navigator.of(context).pop(_savedAny);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    final savedParts = <String>[];
    final failedParts = <String>[];
    try {
      if (nicknameChanged) {
        try {
          await widget.services.auth!.updateNickname(nickname: nickname);
          _savedNickname = nickname;
          _savedAny = true;
          savedParts.add('昵称');
        } catch (_) {
          failedParts.add('昵称');
        }
      }
      if (avatarChanged) {
        final previousAvatarKey = _savedAvatarKey;
        final previousAvatarUrl = _savedAvatarUrl;
        try {
          if (_pickedImage != null) {
            final upload = await widget.services.rooms!.uploadAvatar(
              await _pickedImage!.readAsBytes(),
              _extensionFor(_pickedImage!),
            );
            try {
              await widget.services.auth!.updateAvatar(
                avatarKey: upload.key,
                avatarUrl: upload.url,
                previousAvatarKey: previousAvatarKey,
                previousAvatarUrl: previousAvatarUrl,
              );
            } catch (_) {
              try {
                await widget.services.rooms!.removeAvatarFile(upload.key);
              } catch (_) {}
              rethrow;
            }
            _avatarKey = upload.key;
            _avatarUrl = upload.url;
          } else if (_avatarRemoved) {
            await widget.services.auth!.clearAvatar(
              previousAvatarKey: previousAvatarKey,
              previousAvatarUrl: previousAvatarUrl,
            );
          } else {
            await widget.services.auth!.updateAvatar(
              // 该分支只处理预设头像：未选择图片、未移除且与已保存值不同。
              avatarKey: _avatarKey!,
              previousAvatarKey: previousAvatarKey,
              previousAvatarUrl: previousAvatarUrl,
            );
          }
          _savedAvatarKey = _avatarKey;
          _savedAvatarUrl = _avatarUrl;
          _pickedImage = null;
          _avatarRemoved = false;
          _savedAny = true;
          if (previousAvatarKey != _savedAvatarKey) {
            try {
              await widget.services.rooms!.removeAvatarFile(previousAvatarKey);
            } catch (_) {}
          }
          savedParts.add('头像');
        } catch (_) {
          failedParts.add('头像');
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    if (failedParts.isEmpty) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _message = savedParts.isEmpty
          ? '${failedParts.join('、')}未保存，请重试；${_savedAny ? '已保存部分保持' : '原资料保持'}。'
          : '${savedParts.join('、')}已保存，${failedParts.join('、')}未保存；请重试未成功项。';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.services.currentUser;
    final previewName = _nicknameController.text.trim().isEmpty
        ? user?.nickname ?? '牌友'
        : _nicknameController.text.trim();
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('编辑资料')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            PzBoard(
              title: '头像',
              children: [
                PzBoardRow(
                  avatar: UserAvatar(
                    name: previewName,
                    avatarKey: _avatarKey,
                    avatarUrl: _avatarUrl,
                    radius: 20,
                  ),
                  title: _hasAvatar ? '当前头像' : '未设置头像',
                  detail: '预设头像或选择图片',
                  trailing: TextButton(
                    onPressed: _busy ? null : _selectPreset,
                    child: const Text('选择'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PzButton(
                    label: '选择图片',
                    tone: PzButtonTone.secondary,
                    onPressed: _busy ? null : _pickImage,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PzButton(
                    label: '选择预设',
                    tone: PzButtonTone.secondary,
                    onPressed: _busy ? null : _selectPreset,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PzButton(
                    label: '移除头像',
                    tone: PzButtonTone.secondary,
                    onPressed: _busy || !_hasAvatar ? null : _removeAvatar,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PzLabel('昵称'),
                PzTextField(
                  controller: _nicknameController,
                  enabled: !_busy,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 6),
                const PzHint('最多 40 个字符'),
              ],
            ),
            const SizedBox(height: 12),
            const PzHint('选择头像、修改昵称先更新本地预览；点保存后才提交。'),
            const SizedBox(height: 12),
            PzFormError(_message),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: PzButton(
                    label: '取消',
                    tone: PzButtonTone.secondary,
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: PzButton(label: '保存', busy: _busy, onPressed: _save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
