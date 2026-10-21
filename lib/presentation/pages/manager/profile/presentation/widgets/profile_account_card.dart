import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/utils/formatters/phone_formatter.dart';

/// Account card at the top of every role's profile: avatar, name, role and team, phone.
class ProfileAccountCard extends StatelessWidget {
  /// The signed-in account.
  final AppUser me;

  /// Builds the card.
  const ProfileAccountCard({super.key, required this.me});

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      child: Row(
        children: [
          UserAvatar(me.ref, size: 56.w),
          14.w.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.cardTitle.copyWith(fontSize: 18.sp),
                ),
                Text(
                  '${me.role.title}${me.team.isEmpty ? '' : ' · ${me.team}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.cardSubtitle,
                ),
                if (me.phone.isNotEmpty) Text(PhoneFormatter.display(me.phone), style: theme.cardSubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
