import 'package:flutter/material.dart';
import 'presentation_helpers.dart';

class AvatarPreset {
  const AvatarPreset({
    required this.key,
    required this.emoji,
    required this.color,
  });

  final String key;
  final String emoji;
  final Color color;
}
const avatarPresets = <AvatarPreset>[
  AvatarPreset(key: 'preset:leaf', emoji: '🍃', color: Color(0xFF2F7D68)),
  AvatarPreset(key: 'preset:sun', emoji: '☀️', color: Color(0xFFE29B2D)),
  AvatarPreset(key: 'preset:wave', emoji: '🌊', color: Color(0xFF3B82A0)),
  AvatarPreset(key: 'preset:star', emoji: '⭐', color: Color(0xFF7B61A8)),
  AvatarPreset(key: 'preset:fire', emoji: '🔥', color: Color(0xFFD65A43)),
  AvatarPreset(key: 'preset:moon', emoji: '🌙', color: Color(0xFF44546A)),
];

AvatarPreset? _avatarPresetFor(String? key) {
  for (final preset in avatarPresets) {
    if (preset.key == key) return preset;
  }
  return null;
}

class AvatarPresetDialog extends StatelessWidget {
  const AvatarPresetDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择预设头像'),
      content: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final preset in avatarPresets)
            InkWell(
              onTap: () => Navigator.pop(context, preset.key),
              borderRadius: BorderRadius.circular(36),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: preset.color,
                child: Text(preset.emoji, style: const TextStyle(fontSize: 25)),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key,
    required this.name,
    this.avatarKey,
    this.avatarUrl,
    this.radius = 20,
  });

  final String name;
  final String? avatarKey;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final preset = _avatarPresetFor(avatarKey);
    final fallback = Text(
      preset?.emoji ?? initialFor(name),
      style: preset == null ? null : const TextStyle(fontSize: 20),
    );
    final image = url == null || url.isEmpty
        ? null
        : Image.network(
            url,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          );
    return CircleAvatar(
      radius: radius,
      backgroundColor: preset?.color,
      child: image == null ? fallback : ClipOval(child: image),
    );
  }
}
