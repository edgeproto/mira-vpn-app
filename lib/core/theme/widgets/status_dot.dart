import 'package:flutter/material.dart';

import '../app_colors.dart';

/// High-level connection / health indicator.
enum StatusDotVariant {
  ok,
  warning,
  offline,
}

/// Small circular status indicator.
class StatusDot extends StatelessWidget {
  const StatusDot({
    super.key,
    required this.variant,
    this.size = 10,
  });

  final StatusDotVariant variant;
  final double size;

  Color get _color {
    switch (variant) {
      case StatusDotVariant.ok:
        return AppColors.statusOk;
      case StatusDotVariant.warning:
        return AppColors.statusWarn;
      case StatusDotVariant.offline:
        return AppColors.statusOff;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: switch (variant) {
        StatusDotVariant.ok => 'Status ok',
        StatusDotVariant.warning => 'Status warning',
        StatusDotVariant.offline => 'Status offline',
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
