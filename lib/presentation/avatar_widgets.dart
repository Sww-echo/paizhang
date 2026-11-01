import 'package:flutter/material.dart';

import 'design.dart';
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
  AvatarPreset(key: 'preset:leaf', emoji: '🍃', color: PzAvatarColors.leaf),
  AvatarPreset(key: 'preset:sun', emoji: '☀️', color: PzAvatarColors.sun),
  AvatarPreset(key: 'preset:wave', emoji: '🌊', color: PzAvatarColors.wave),
  AvatarPreset(key: 'preset:star', emoji: '⭐', color: PzAvatarColors.star),
  AvatarPreset(key: 'preset:fire', emoji: '🔥', color: PzAvatarColors.fire),
  AvatarPreset(key: 'preset:moon', emoji: '🌙', color: PzAvatarColors.moon),
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
    return PzDialogShell(
      title: '选择预设头像',
      actions: [
        PzButton(
          label: '取消',
          tone: PzButtonTone.secondary,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      children: [
        Wrap(
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
                  child: Text(
                    preset.emoji,
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
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
