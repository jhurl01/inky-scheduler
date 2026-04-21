import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The date currently displayed in the Today / Day view.
/// Updated by TodayScreen so the FAB in the shell knows which date to default.
final viewedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
