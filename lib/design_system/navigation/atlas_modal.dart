import 'package:flutter/material.dart';

import '../theme/atlas_motion.dart';

/// Bottom sheet Atlas — entrée type ressort adouci.
Future<T?> showAtlasBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = true,
  bool useSafeArea = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
}) {
  final reduce = AtlasMotion.reduceMotionOf(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    useSafeArea: useSafeArea,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useRootNavigator: useRootNavigator,
    sheetAnimationStyle: AnimationStyle(
      duration: reduce ? Duration.zero : AtlasMotion.sheetDuration,
      reverseDuration:
          reduce ? Duration.zero : AtlasMotion.sheetReverseDuration,
      curve: AtlasMotion.curveSpring,
      reverseCurve: AtlasMotion.curveExit,
    ),
    builder: builder,
  );
}

/// Dialogue Atlas — fade + scale via theme (durée standardisée).
Future<T?> showAtlasDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final reduce = AtlasMotion.reduceMotionOf(context);
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    animationStyle: AnimationStyle(
      duration: reduce ? Duration.zero : AtlasMotion.dialogDuration,
      reverseDuration: reduce ? Duration.zero : AtlasMotion.durationMicro,
      curve: AtlasMotion.curveEnter,
      reverseCurve: AtlasMotion.curveExit,
    ),
    builder: builder,
  );
}
