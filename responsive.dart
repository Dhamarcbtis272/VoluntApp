import 'package:flutter/material.dart';

class ResponsiveSize {
  final BuildContext context;
  final double width;
  final double height;
  final bool isMobile;

  ResponsiveSize(this.context)
      : width = MediaQuery.of(context).size.width,
        height = MediaQuery.of(context).size.height,
        isMobile = MediaQuery.of(context).size.width < 600;

  double get appBarTitleSize => isMobile ? 20 : 24;
  double get screenTitleSize => isMobile ? 24 : 32;
  double get headingSize => isMobile ? 20 : 28;
  double get bodySize => isMobile ? 16 : 18;
  double get smallSize => isMobile ? 14 : 16;
  double get smallSpacing => isMobile ? 10 : 16;
  double get mediumSpacing => isMobile ? 16 : 24;
  double get largeSpacing => isMobile ? 24 : 32;
}
