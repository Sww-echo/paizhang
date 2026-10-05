import 'package:flutter/material.dart';
import '../domain/models.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../domain/invite_service.dart';
import 'presentation_helpers.dart';

class ConnectedActionButton extends StatelessWidget {
  const ConnectedActionButton({super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: primary
            ? const Color(0xFF2F7D68)
            : const Color(0xFFE8E5DA),
        foregroundColor: primary ? Colors.white : const Color(0xFF17342F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
class ConnectedRoomTile extends StatelessWidget {
  const ConnectedRoomTile({super.key, required this.room, required this.onTap});

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.groups_rounded)),
        title: Text(room.name),
        subtitle: Text(
          '${room.members.where((member) => member.isActive).length} 位成员 · ${room.gameType}',
        ),
        trailing: Text(roomStatusLabel(room.status)),
      ),
    );
  }
}

class RoomFormValue {
  const RoomFormValue({
    required this.name,
    required this.gameType,
    required this.scoringMode,
  });

  final String name;
  final String gameType;
  final ScoringMode scoringMode;
}

class RoomFormDialog extends StatefulWidget {
  const RoomFormDialog({super.key,
    this.title = '创建房间',
    this.submitLabel = '创建',
    this.initialName = '',
    this.initialGameType = '掼蛋',
    this.initialScoringMode = ScoringMode.points,
  });

  final String title;
  final String submitLabel;
  final String initialName;
  final String initialGameType;
  final ScoringMode initialScoringMode;

  @override
  State<RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<RoomFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _gameTypeController;
  late ScoringMode _scoringMode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _gameTypeController = TextEditingController(text: widget.initialGameType);
    _scoringMode = widget.initialScoringMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gameTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '房间名称'),
          ),
          TextField(
            controller: _gameTypeController,
            decoration: const InputDecoration(labelText: '玩法'),
          ),
          DropdownButtonFormField<ScoringMode>(
            initialValue: _scoringMode,
            decoration: const InputDecoration(labelText: '记分方式'),
            items: const [
              DropdownMenuItem(value: ScoringMode.points, child: Text('积分')),
              DropdownMenuItem(value: ScoringMode.money, child: Text('金额')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _scoringMode = value);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final gameType = _gameTypeController.text.trim();
            if (name.isEmpty || gameType.isEmpty) {
              setState(() => _error = '请填写房间名称和玩法');
              return;
            }
            Navigator.pop(
              context,
              RoomFormValue(
                name: name,
                gameType: gameType,
                scoringMode: _scoringMode,
              ),
            );
          },
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class JoinRoomDialog extends StatefulWidget {
  const JoinRoomDialog({super.key});

  @override
  State<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<JoinRoomDialog> {
  final _codeController = TextEditingController();

  Future<void> _scanInvite() async {
    final scannedValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const InviteScannerPage()),
    );
    if (!mounted || scannedValue == null) return;
    _codeController
      ..text = scannedValue
      ..selection = TextSelection.collapsed(offset: scannedValue.length);
    setState(() {});
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('加入房间'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: '邀请码或分享链接'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _scanInvite,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('扫码'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _codeController.text),
          child: const Text('加入'),
        ),
      ],
    );
  }
}

class InviteScannerPage extends StatefulWidget {
  const InviteScannerPage({super.key});

  @override
  State<InviteScannerPage> createState() => _InviteScannerPageState();
}

class _InviteScannerPageState extends State<InviteScannerPage> {
  String? _errorMessage;
  String? _lastScannedValue;
  bool _isClosing = false;

  void _handleDetection(BarcodeCapture capture) {
    if (_isClosing) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue == null ||
          rawValue.isEmpty ||
          rawValue == _lastScannedValue) {
        continue;
      }
      _lastScannedValue = rawValue;
      final token = const InviteService().extractToken(rawValue);
      if (token == null) {
        if (mounted) {
          setState(() => _errorMessage = '二维码不是有效的牌账邀请链接');
        }
        return;
      }
      _isClosing = true;
      Navigator.of(context).pop(rawValue);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫描邀请二维码')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(onDetect: _handleDetection),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          if (_errorMessage != null)
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TextInputDialog extends StatefulWidget {
  const TextInputDialog({super.key,
    required this.title,
    required this.label,
    required this.confirmLabel,
    this.initialValue = '',
  });

  final String title;
  final String label;
  final String confirmLabel;
  final String initialValue;

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: widget.label),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isEmpty) {
              setState(() => _error = '内容不能为空');
              return;
            }
            Navigator.pop(context, value);
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
