import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';

/// Round avatar: the person's picture when they have one, otherwise (and while it loads or fails) their initials on
/// a palette color.
class UserAvatar extends StatelessWidget {
  /// The person to draw.
  final UserRef user;

  /// Diameter; defaults to 32.w.
  final double? size;

  /// Builds the avatar.
  const UserAvatar(this.user, {super.key, this.size});

  /// Palette the avatar background is picked from by [UserRef.color].
  static const _palette = [
    Color(0xFF2F6B4F),
    Color(0xFF8A5530),
    Color(0xFF3A5E9E),
    Color(0xFF8A3D5C),
    Color(0xFF5E6230),
    Color(0xFF5B4A8F),
  ];

  @override
  Widget build(BuildContext context) {
    final diameter = size ?? 32.w;
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: _palette[user.color % _palette.length], shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            user.initials,
            style: theme.badgeText.copyWith(
              fontSize: diameter * 0.37,
              color: const Color(0xFFFFFFFF),
              letterSpacing: 0.3,
            ),
          ),
          if (user.avatarUrl.isNotEmpty)
            ClipOval(
              child: Image.network(
                user.avatarUrl,
                width: diameter,
                height: diameter,
                fit: BoxFit.cover,
                cacheWidth: (diameter * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                frameBuilder: (_, image, frame, sync) => frame == null && !sync ? const SizedBox.shrink() : image,
              ),
            ),
        ],
      ),
    );
  }
}

/// Overlapping avatars of several people with a "+N" tail after three.
class AvatarStack extends StatelessWidget {
  /// People to draw.
  final List<UserRef> users;

  /// Diameter of each avatar; defaults to 24.w.
  final double? size;

  /// Builds the stack.
  const AvatarStack(this.users, {super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final diameter = size ?? 24.w;
    final shown = users.take(3).toList();
    final slots = shown.length + (users.length > 3 ? 1 : 0);
    // Each avatar overlaps the previous one by a third of its diameter.
    final step = diameter * 0.65;
    return SizedBox(
      height: diameter,
      width: diameter + (slots - 1) * step,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardColor, width: 2),
                ),
                child: UserAvatar(shown[i], size: diameter),
              ),
            ),
          if (users.length > 3)
            Positioned(
              left: 3 * step,
              child: Container(
                width: diameter,
                height: diameter,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.cardColorLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardColor, width: 2),
                ),
                child: Text(
                  '+${users.length - 3}',
                  style: theme.badgeText.copyWith(fontSize: diameter * 0.37, color: theme.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
