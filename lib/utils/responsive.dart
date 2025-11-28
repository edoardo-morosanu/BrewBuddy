import 'package:flutter/material.dart';

/// Responsive breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Device type
enum DeviceType { mobile, tablet, desktop }

/// Responsive utilities for consistent sizing across devices
class Responsive {
  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.mobile) return DeviceType.mobile;
    if (width < Breakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  /// Check if screen is small (height < 700)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.height < 700;
  }

  /// Check if screen is extra small (height < 600)
  static bool isExtraSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.height < 600;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    final deviceType = getDeviceType(context);
    final padding = switch (deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet,
      DeviceType.desktop => desktop,
    };
    return EdgeInsets.all(padding);
  }

  /// Get responsive horizontal padding
  static EdgeInsets getHorizontalPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    final deviceType = getDeviceType(context);
    final padding = switch (deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet,
      DeviceType.desktop => desktop,
    };
    return EdgeInsets.symmetric(horizontal: padding);
  }

  /// Get responsive vertical padding
  static EdgeInsets getVerticalPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    final deviceType = getDeviceType(context);
    final padding = switch (deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet,
      DeviceType.desktop => desktop,
    };
    return EdgeInsets.symmetric(vertical: padding);
  }

  /// Get responsive value based on device type
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    return switch (deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet ?? mobile,
      DeviceType.desktop => desktop ?? tablet ?? mobile,
    };
  }

  /// Get responsive font size
  static double getFontSize(
    BuildContext context, {
    required double base,
    double? tablet,
    double? desktop,
  }) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;
    final scaleFactor = isSmall ? 0.9 : 1.0;

    return getValue<double>(
      context,
      mobile: base * scaleFactor,
      tablet: (tablet ?? base) * scaleFactor,
      desktop: (desktop ?? tablet ?? base) * scaleFactor,
    );
  }

  /// Get responsive spacing
  static double getSpacing(
    BuildContext context, {
    required double base,
    double? tablet,
    double? desktop,
  }) {
    final isSmall = isSmallScreen(context);
    final scaleFactor = isSmall ? 0.75 : 1.0;

    return getValue<double>(
      context,
      mobile: base * scaleFactor,
      tablet: (tablet ?? base) * scaleFactor,
      desktop: (desktop ?? tablet ?? base) * scaleFactor,
    );
  }

  /// Get responsive icon size
  static double getIconSize(
    BuildContext context, {
    required double base,
    double? tablet,
    double? desktop,
  }) {
    return getValue<double>(
      context,
      mobile: base,
      tablet: tablet ?? base,
      desktop: desktop ?? tablet ?? base,
    );
  }

  /// Get maximum content width for responsive layouts
  static double getMaxContentWidth(BuildContext context) {
    final deviceType = getDeviceType(context);
    return switch (deviceType) {
      DeviceType.mobile => double.infinity,
      DeviceType.tablet => 720,
      DeviceType.desktop => 800,
    };
  }

  /// Get maximum content width with custom values per device type
  static double getMaxContentWidthCustom(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = getDeviceType(context);
    return switch (deviceType) {
      DeviceType.mobile => mobile ?? double.infinity,
      DeviceType.tablet => tablet ?? 720,
      DeviceType.desktop => desktop ?? 800,
    };
  }

  /// Get responsive horizontal padding for content areas
  static double getHorizontalContentPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.mobile) return 24;
    if (width < Breakpoints.tablet) return 32;
    if (width < Breakpoints.desktop) return 48;
    return 64;
  }

  /// Get responsive vertical padding for content areas
  static double getVerticalContentPadding(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    if (height < 600) return 16;
    if (height < 700) return 20;
    return 24;
  }

  /// Get responsive card width
  static double getCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final deviceType = getDeviceType(context);

    return switch (deviceType) {
      DeviceType.mobile => width * 0.9,
      DeviceType.tablet => width * 0.7,
      DeviceType.desktop => 600,
    };
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    final isSmall = isSmallScreen(context);
    return isSmall ? 48 : 56;
  }

  /// Get responsive border radius
  static double getBorderRadius(BuildContext context, {double base = 16}) {
    return getValue<double>(
      context,
      mobile: base,
      tablet: base + 4,
      desktop: base + 8,
    );
  }

  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Responsive builder widget
  static Widget builder({
    required BuildContext context,
    required Widget Function(BuildContext, DeviceType) builder,
  }) {
    final deviceType = getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// Extension on BuildContext for easy access to responsive utilities
extension ResponsiveContext on BuildContext {
  /// Get device type
  DeviceType get deviceType => Responsive.getDeviceType(this);

  /// Check if mobile
  bool get isMobile => Responsive.isMobile(this);

  /// Check if tablet
  bool get isTablet => Responsive.isTablet(this);

  /// Check if desktop
  bool get isDesktop => Responsive.isDesktop(this);

  /// Check if small screen
  bool get isSmallScreen => Responsive.isSmallScreen(this);

  /// Check if extra small screen
  bool get isExtraSmallScreen => Responsive.isExtraSmallScreen(this);

  /// Check if keyboard is visible
  bool get isKeyboardVisible => Responsive.isKeyboardVisible(this);

  /// Get responsive padding
  EdgeInsets responsivePadding({
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) => Responsive.getPadding(
    this,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );

  /// Get responsive horizontal padding
  EdgeInsets responsiveHorizontalPadding({
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) => Responsive.getHorizontalPadding(
    this,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );

  /// Get responsive vertical padding
  EdgeInsets responsiveVerticalPadding({
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) => Responsive.getVerticalPadding(
    this,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );

  /// Get responsive value
  T responsiveValue<T>({required T mobile, T? tablet, T? desktop}) =>
      Responsive.getValue<T>(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );

  /// Get responsive font size
  double responsiveFontSize({
    required double base,
    double? tablet,
    double? desktop,
  }) => Responsive.getFontSize(
    this,
    base: base,
    tablet: tablet,
    desktop: desktop,
  );

  /// Get responsive spacing
  double responsiveSpacing({
    required double base,
    double? tablet,
    double? desktop,
  }) =>
      Responsive.getSpacing(this, base: base, tablet: tablet, desktop: desktop);

  /// Get responsive icon size
  double responsiveIconSize({
    required double base,
    double? tablet,
    double? desktop,
  }) => Responsive.getIconSize(
    this,
    base: base,
    tablet: tablet,
    desktop: desktop,
  );

  /// Get maximum content width
  double get maxContentWidth => Responsive.getMaxContentWidth(this);

  /// Get maximum content width with custom values
  double maxContentWidthCustom({
    double? mobile,
    double? tablet,
    double? desktop,
  }) => Responsive.getMaxContentWidthCustom(
    this,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );

  /// Get responsive card width
  double get cardWidth => Responsive.getCardWidth(this);

  /// Get responsive button height
  double get buttonHeight => Responsive.getButtonHeight(this);

  /// Get responsive border radius
  double responsiveBorderRadius({double base = 16}) =>
      Responsive.getBorderRadius(this, base: base);

  /// Get horizontal content padding
  double get horizontalContentPadding =>
      Responsive.getHorizontalContentPadding(this);

  /// Get vertical content padding
  double get verticalContentPadding =>
      Responsive.getVerticalContentPadding(this);
}
