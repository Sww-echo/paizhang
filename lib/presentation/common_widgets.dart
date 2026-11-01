import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../domain/invite_service.dart';
import '../domain/models.dart';
import 'design.dart';
import 'presentation_helpers.dart';

class ConnectedActionButton extends StatelessWidget {
  const ConnectedActionButton({
    super.key,
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
    return PzButton(
      label: label,
      icon: icon,
      tone: primary ? PzButtonTone.primary : PzButtonTone.secondary,
      onPressed: onPressed,
    );
  }
}

class ConnectedRoomTile extends StatelessWidget {
  const ConnectedRoomTile({super.key, required this.room, required this.onTap});

  final Room room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    final memberCount = room.members.where((member) => member.isActive).length;
    return PzBoardRow(
      avatar: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: room.isClosed ? c.sunken : c.tint,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.groups_rounded,
          size: 17,
          color: room.isClosed ? c.muted : c.brandInk,
        ),
      ),
      title: room.name,
      detail:
          '$memberCount 人 · ${room.gameType} · ${roomStatusLabel(room.status)}',
      trailing: Text('进入', style: TextStyle(fontSize: 12, color: c.muted)),
      onTap: onTap,
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
  const RoomFormDialog({
    super.key,
    this.title = '创建房间',
    this.submitLabel = '创建房间',
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
    final c = PzColors.of(context);
    return PzDialogShell(
      title: widget.title,
      maxWidth: 480,
      actions: [
        PzButton(
          label: '取消',
          tone: PzButtonTone.secondary,
          onPressed: () => Navigator.pop(context),
        ),
        PzButton(
          label: widget.submitLabel,
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
        ),
      ],
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PzLabel('房间名称'),
            PzTextField(controller: _nameController, autofocus: true),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PzLabel('玩法'),
            PzTextField(controller: _gameTypeController),
          ],
        ),
        PzBoard(
          title: '记分方式',
          children: [
            for (final option in ScoringMode.values)
              PzBoardRow(
                title: option == ScoringMode.money ? '金额' : '积分',
                detail: option == ScoringMode.money ? '每回合必须合计为 0' : '允许不平账',
                trailing: Text(
                  _scoringMode == option ? '已选' : '选择',
                  style: TextStyle(
                    fontSize: 12,
                    color: _scoringMode == option ? c.brandInk : c.muted,
                  ),
                ),
                onTap: () => setState(() => _scoringMode = option),
              ),
          ],
        ),
        const PzHint('已有回合后记分方式不可修改。创建成功进入房间，房间内独立创建牌局。'),
        PzFormError(_error),
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
    return PzDialogShell(
      title: '加入房间',
      subtitle: '邀请码输入、扫码和链接只负责识别，加入后进入记分台。',
      actions: [
        PzButton(
          label: '取消',
          tone: PzButtonTone.secondary,
          onPressed: () => Navigator.pop(context),
        ),
        PzButton(
          label: '加入房间',
          onPressed: () => Navigator.pop(context, _codeController.text),
        ),
      ],
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PzLabel('邀请码或分享链接'),
            PzTextField(
              controller: _codeController,
              autofocus: true,
              hint: '例如 PZ-7K4Q 或分享链接',
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: PzButton(
            label: '扫码',
            tone: PzButtonTone.ghost,
            icon: Icons.qr_code_scanner_rounded,
            onPressed: _scanInvite,
          ),
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
              child: PzNotice(message: _errorMessage!),
            ),
        ],
      ),
    );
  }
}
