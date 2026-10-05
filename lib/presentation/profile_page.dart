import '../infrastructure/backend/app_error_mapper.dart';
import 'package:flutter/material.dart';
import '../application/app_services.dart';
import 'package:image_picker/image_picker.dart';
import 'avatar_widgets.dart';
import 'history_pages.dart';

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
  bool _avatarBusy = false;

  @override
  void initState() {
    super.initState();
    final user = widget.services.currentUser;
    _nickname = user?.nickname.trim() ?? '';
    _avatarKey = user?.avatarKey;
    _avatarUrl = user?.avatarUrl;
  }

  Future<void> _pickAvatar() async {
    if (_avatarBusy) return;
    setState(() => _avatarBusy = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image == null || !mounted) return;
      final oldKey = _avatarKey;
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
      final upload = await widget.services.rooms!.uploadAvatar(
        await image.readAsBytes(),
        extension,
      );
      try {
        await widget.services.auth!.updateAvatar(
          avatarKey: upload.key,
          avatarUrl: upload.url,
          previousAvatarKey: oldKey,
          previousAvatarUrl: _avatarUrl,
        );
      } catch (_) {
        try {
          await widget.services.rooms!.removeAvatarFile(upload.key);
        } catch (_) {}
        rethrow;
      }
      if (oldKey != null) {
        try {
          await widget.services.rooms!.removeAvatarFile(oldKey);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _avatarKey = upload.key;
          _avatarUrl = upload.url;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('头像已更新')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mapAppError(error).message)));
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _selectPresetAvatar() async {
    if (_avatarBusy) return;
    final avatarKey = await showDialog<String>(
      context: context,
      builder: (context) => const AvatarPresetDialog(),
    );
    if (avatarKey == null || !mounted) return;
    setState(() => _avatarBusy = true);
    final oldKey = _avatarKey;
    try {
      await widget.services.auth!.updateAvatar(
        avatarKey: avatarKey,
        previousAvatarKey: oldKey,
        previousAvatarUrl: _avatarUrl,
      );
      if (oldKey != null) {
        try {
          await widget.services.rooms!.removeAvatarFile(oldKey);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _avatarKey = avatarKey;
          _avatarUrl = null;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('预设头像已更新')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mapAppError(error).message)));
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _removeAvatar() async {
    if (_avatarBusy || (_avatarKey == null && _avatarUrl == null)) return;
    setState(() => _avatarBusy = true);
    final oldKey = _avatarKey;
    try {
      await widget.services.auth!.clearAvatar(
        previousAvatarKey: oldKey,
        previousAvatarUrl: _avatarUrl,
      );
      try {
        await widget.services.rooms!.removeAvatarFile(oldKey);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _avatarKey = null;
          _avatarUrl = null;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('头像已删除')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mapAppError(error).message)));
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _editNickname() async {
    if (_avatarBusy) return;
    final controller = TextEditingController(text: _nickname);
    final nickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(labelText: '昵称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nickname == null || nickname.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _avatarBusy = true);
    try {
      await widget.services.auth!.updateNickname(nickname: nickname.trim());
      if (mounted) setState(() => _nickname = nickname.trim());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mapAppError(error).message)));
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConnectedHistoryPage(services: widget.services),
      ),
    );
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
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 28),
        Card(
          elevation: 0,
          child: ListTile(
            leading: UserAvatar(
              name: displayName,
              avatarKey: _avatarKey,
              avatarUrl: _avatarUrl,
              radius: 26,
            ),
            title: Text(displayName),
            subtitle: Text(user?.email ?? user?.phone ?? ''),
            trailing: const Icon(Icons.edit_rounded),
            onTap: _editNickname,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.photo_camera_back_rounded),
            title: const Text('头像'),
            subtitle: Text(
              _avatarKey == null && _avatarUrl == null
                  ? '未设置头像'
                  : '支持预设头像或图片头像',
            ),
            trailing: _avatarBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'preset') _selectPresetAvatar();
                      if (value == 'pick') _pickAvatar();
                      if (value == 'remove') _removeAvatar();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'preset',
                        child: Text('选择预设头像'),
                      ),
                      const PopupMenuItem(value: 'pick', child: Text('选择图片')),
                      if (_avatarKey != null || _avatarUrl != null)
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('删除头像'),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('历史记录'),
            subtitle: const Text('查看个人和房间的过往牌局'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _openHistory,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => widget.services.auth!.signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('退出登录'),
        ),
      ],
    );
  }
}
