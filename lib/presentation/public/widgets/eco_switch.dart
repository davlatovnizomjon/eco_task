import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// The 48×28 on/off toggle of the settings and forms.
class EcoSwitch extends StatelessWidget {
  /// Current value.
  final bool value;

  /// Called with the new value when tapped; null disables the toggle.
  final ValueChanged<bool>? onChanged;

  /// Builds the toggle.
  const EcoSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48.w,
        height: 28.h,
        padding: 3.w.all,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(color: value ? theme.primary : theme.line, borderRadius: 14.circular),
        child: Container(
          width: 22.w,
          height: 22.w,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x40000000))],
          ),
        ),
      ),
    );
  }
}
