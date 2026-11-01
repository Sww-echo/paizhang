import 'package:flutter/material.dart';

import 'design.dart';

/// 加载失败卡片：保留已有内容，就地重试。
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    return PzBoard(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: c.win),
                  const SizedBox(width: 8),
                  Text(
                    '加载失败',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.fg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(message, style: TextStyle(fontSize: 13, color: c.muted)),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: PzButton(
                  label: '重试',
                  tone: PzButtonTone.ghost,
                  onPressed: onRetry,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 房间访问已变化：停止当前操作，提供返回入口。
class RoomAccessErrorCard extends StatelessWidget {
  const RoomAccessErrorCard({
    super.key,
    required this.message,
    required this.onBack,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = PzColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PzBoard(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 42, color: c.muted),
                  const SizedBox(height: 12),
                  Text(
                    '房间访问已变化',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: c.fg,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: c.muted),
                  ),
                  const SizedBox(height: 16),
                  PzButton(
                    label: '返回',
                    tone: PzButtonTone.secondary,
                    onPressed: onBack,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
