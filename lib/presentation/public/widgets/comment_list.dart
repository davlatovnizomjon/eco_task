import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/comment_model.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import 'user_avatar.dart';

/// Chat-style list of comments: avatar, author, time and a bubble. The
/// signed-in user's own comments are labelled "Siz". Shared by task details
/// and request details.
class CommentList extends StatelessWidget {
  /// Comments, oldest first.
  final List<CommentModel> comments;

  /// Id of the signed-in user, to label their own comments.
  final String meId;

  /// Builds the list.
  const CommentList({super.key, required this.comments, required this.meId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final c in comments)
          Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(c.user),
                10.w.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.user.id == meId ? TrWords.cMe.tr() : c.user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.cardTitle.copyWith(fontSize: 14.sp),
                            ),
                          ),
                          Text(' · ${DateFormatter.time(c.at)}', style: theme.cardSubtitle),
                        ],
                      ),
                      4.h.height,
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: theme.cardColorLight,
                          borderRadius: BorderRadius.only(
                            topRight: 14.circularRadius,
                            bottomLeft: 14.circularRadius,
                            bottomRight: 14.circularRadius,
                          ),
                        ),
                        child: Text(c.text, style: theme.textStyle.copyWith(fontWeight: FontWeight.w400, height: 1.35)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
