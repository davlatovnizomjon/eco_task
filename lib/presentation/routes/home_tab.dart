import 'package:flutter/foundation.dart';

/// Index of the selected section of the role shell (the left menu's in-shell entries). Any screen
/// can switch tabs ("see all" links) by assigning it; only the role shell
/// listens. It is UI navigation state, not business state, so it lives next to
/// the routes rather than in a bloc.
final ValueNotifier<int> homeTab = ValueNotifier<int>(0);
