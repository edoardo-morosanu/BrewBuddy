import 'package:flutter/material.dart';

/// Responsive breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Device type
enum DeviceType { mobile, tablet, desktop }

/// A value that adapts to the device type.
///
/// This class encapsulates the logic for selecting a value based on the current
/// device type (mobile, tablet, desktop), reducing primitive obsession and
/// duplication in responsive logic.
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({required this.mobile, this.tablet, this.desktop});

  /// Resolves the value based on the [BuildContext].
  T resolve(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);
    return switch (deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet ?? mobile,
      DeviceType.desktop => desktop ?? tablet ?? mobile,
    };
  }
}

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
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  /// Check if device is tablet
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  /// Check if screen is small (height < 700)
  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.height < 700;

  /// Check if screen is extra small (height < 600)
  static bool isExtraSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.height < 600;

  /// Get responsive value based on device type
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return ResponsiveValue<T>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    ).resolve(context);
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    return EdgeInsets.all(
      getValue(context, mobile: mobile, tablet: tablet, desktop: desktop),
    );
  }

  /// Get responsive horizontal padding
  static EdgeInsets getHorizontalPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    return EdgeInsets.symmetric(
      horizontal: getValue(
        context,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      ),
    );
  }

  /// Get responsive vertical padding
  static EdgeInsets getVerticalPadding(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    return EdgeInsets.symmetric(
      vertical: getValue(
        context,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      ),
    );
  }

  /// Get responsive font size
  static double getFontSize(
    BuildContext context, {
    required double base,
    double? tablet,
    double? desktop,
  }) {
    final isSmall = isSmallScreen(context);
    final scaleFactor = isSmall ? 0.9 : 1.0;
    final value = getValue(
      context,
      mobile: base,
      tablet: tablet,
      desktop: desktop,
    );
    return value * scaleFactor;
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
    final value = getValue(
      context,
      mobile: base,
      tablet: tablet,
      desktop: desktop,
    );
    return value * scaleFactor;
  }

  /// Get responsive icon size
  static double getIconSize(
    BuildContext context, {
    required double base,
    double? tablet,
    double? desktop,
  }) {
    return getValue(context, mobile: base, tablet: tablet, desktop: desktop);
  }

  /// Get maximum content width for responsive layouts
  static double getMaxContentWidth(BuildContext context) {
    return getValue(
      context,
      mobile: double.infinity,
      tablet: 720,
      desktop: 800,
    );
  }

  /// Get maximum content width with custom values per device type
  static double getMaxContentWidthCustom(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    return getValue(
      context,
      mobile: mobile ?? double.infinity,
      tablet: tablet ?? 720,
      desktop: desktop ?? 800,
    );
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
    return getValue(
      context,
      mobile: width * 0.9,
      tablet: width * 0.7,
      desktop: 600.0,
    );
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    return isSmallScreen(context) ? 48 : 56;
  }

  /// Get responsive border radius
  static double getBorderRadius(BuildContext context, {double base = 16}) {
    return getValue(context, mobile: base, tablet: base + 4, desktop: base + 8);
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
    return builder(context, getDeviceType(context));
  }
}

/// Extension on BuildContext for easy access to responsive utilities
extension ResponsiveContext on BuildContext {
  DeviceType get deviceType => Responsive.getDeviceType(this);
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get isSmallScreen => Responsive.isSmallScreen(this);
  bool get isExtraSmallScreen => Responsive.isExtraSmallScreen(this);
  bool get isKeyboardVisible => Responsive.isKeyboardVisible(this);

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

  T responsiveValue<T>({required T mobile, T? tablet, T? desktop}) =>
      Responsive.getValue<T>(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );

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

  double responsiveSpacing({
    required double base,
    double? tablet,
    double? desktop,
  }) =>
      Responsive.getSpacing(this, base: base, tablet: tablet, desktop: desktop);

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

  double get maxContentWidth => Responsive.getMaxContentWidth(this);

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

  double get cardWidth => Responsive.getCardWidth(this);
  double get buttonHeight => Responsive.getButtonHeight(this);
  double responsiveBorderRadius({double base = 16}) =>
      Responsive.getBorderRadius(this, base: base);
  double get horizontalContentPadding =>
      Responsive.getHorizontalContentPadding(this);
  double get verticalContentPadding =>
      Responsive.getVerticalContentPadding(this);
}
