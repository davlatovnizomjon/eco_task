import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'profile_frame.dart';

/// Profile section of the admin: the shared account card, settings and sign-out (everything else is in the left menu).
class AdminProfileScreen extends StatelessWidget {
  /// Builds the profile section.
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileFrame(title: TrWords.navProfile.tr(), sections: (_, _) => const []);
  }
}
