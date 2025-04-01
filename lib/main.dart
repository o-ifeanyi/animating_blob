import 'dart:math' as math;
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:mesh_gradient/mesh_gradient.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int speed = 1;
  double size = 300;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        body: Column(
          children: [
            const Spacer(),
            AnimatedBlob(key: ValueKey(speed + size), size: size, speed: speed),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                IconButton.outlined(
                  onPressed: () {
                    if (speed <= 1) return;
                    setState(() {
                      speed -= 1;
                    });
                  },
                  icon: Icon(Icons.remove_rounded),
                ),
                Text('Speed: $speed'),
                IconButton.outlined(
                  onPressed: () {
                    if (speed >= 5) return;
                    setState(() {
                      speed += 1;
                    });
                  },
                  icon: Icon(Icons.add_rounded),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                IconButton.outlined(
                  onPressed: () {
                    if (size <= 50) return;
                    setState(() {
                      size -= 50;
                    });
                  },
                  icon: Icon(Icons.remove_rounded),
                ),
                Text('Size: $size'),
                IconButton.outlined(
                  onPressed: () {
                    if (size >= 400) return;
                    setState(() {
                      size += 50;
                    });
                  },
                  icon: Icon(Icons.add_rounded),
                ),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class AnimatedBlob extends StatefulWidget {
  const AnimatedBlob({this.speed = 1, this.size = 200, super.key})
    : assert(
        speed >= 1 && speed <= 5,
        'Speed factor should be an int between 1 and 5(inclusive)',
      );

  /// min 1, max 5
  final int speed;
  final double size;

  @override
  State<AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<BlobPoint> _points;

  List<BlobPoint> _createBlobPoints({
    required int numPoints,
    required double centerX,
    required double centerY,
    required double minRadius,
    required double maxRadius,
    required double minDuration,
    required double maxDuration,
  }) {
    final points = <BlobPoint>[];
    final slice = 2 * math.pi / numPoints;
    final startAngle = _random(0, 2 * math.pi);

    for (var i = 0; i < numPoints; i++) {
      final angle = startAngle + i * slice;
      final duration = _random(minDuration, maxDuration);
      final point = BlobPoint(
        centerX: centerX,
        centerY: centerY,
        angle: angle,
        minRadius: minRadius,
        maxRadius: maxRadius,
        phase: _random(0, duration),
        duration: duration,
      );
      points.add(point);
    }
    return points;
  }

  double _random(double min, double max) {
    return min + (max - min) * math.Random().nextDouble();
  }

  double get _size => widget.size;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10 ~/ widget.speed),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);

    _controller.repeat(reverse: true);

    _points = _createBlobPoints(
      numPoints: 7,
      centerX: _size / 2,
      centerY: _size / 2,
      minRadius: _size * 0.4,
      maxRadius: _size * 0.5,
      minDuration: 2,
      maxDuration: 4,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.isDark ? lightColorScheme : darkColorScheme;
    return SizedBox(
      width: _size,
      height: _size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ClipPath(
            clipper: BlobPath(_points, _animation.value),
            child: AnimatedMeshGradient(
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
                colorScheme.tertiary,
                colorScheme.surfaceDim,
              ],
              options: AnimatedMeshGradientOptions(
                speed: widget.speed * 3,
                amplitude: 25,
              ),
            ),
          );
        },
      ),
    );
  }
}

class BlobPath extends CustomClipper<Path> {
  const BlobPath(this.points, this.animationValue);

  final List<BlobPoint> points;
  final double animationValue;

  @override
  Path getClip(Size size) => _cardinalSpline(points, true, 1, animationValue);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

Path _cardinalSpline(
  List<BlobPoint> data,
  bool closed,
  double tension,
  double t,
) {
  final path = Path();
  if (data.isEmpty) return path..moveTo(0, 0);

  final size = data.length - (closed ? 0 : 1);
  final positions = data.map((p) => p.getPosition(t)).toList();

  path.moveTo(positions[0].dx, positions[0].dy);

  for (var i = 0; i < size; i++) {
    Offset p0;
    Offset p1;
    Offset p2;
    Offset p3;

    if (closed) {
      p0 = positions[(i - 1 + size) % size];
      p1 = positions[i];
      p2 = positions[(i + 1) % size];
      p3 = positions[(i + 2) % size];
    } else {
      p0 = i == 0 ? positions[0] : positions[i - 1];
      p1 = positions[i];
      p2 = positions[i + 1];
      p3 = i == size - 1 ? p2 : positions[i + 2];
    }

    final x1 = p1.dx + ((p2.dx - p0.dx) / 6) * tension;
    final y1 = p1.dy + ((p2.dy - p0.dy) / 6) * tension;
    final x2 = p2.dx - ((p3.dx - p1.dx) / 6) * tension;
    final y2 = p2.dy - ((p3.dy - p1.dy) / 6) * tension;

    path.cubicTo(x1, y1, x2, y2, p2.dx, p2.dy);
  }

  if (closed) path.close();
  return path;
}

class BlobPoint {
  const BlobPoint({
    required this.centerX,
    required this.centerY,
    required this.angle,
    required this.minRadius,
    required this.maxRadius,
    required this.phase,
    required this.duration,
  });
  final double centerX;
  final double centerY;
  final double angle;
  final double minRadius;
  final double maxRadius;
  final double phase;
  final double duration;

  Offset getPosition(double t) {
    // Soften the transition by adjusting the progress calculation
    final progress = (t * duration + phase) % 1;
    // Use a smoother interpolation instead of sharp sine
    final eased =
        0.5 - 0.5 * math.cos(progress * 2 * math.pi); // 0 to 1 and back
    final radius = minRadius + (maxRadius - minRadius) * eased;
    return Offset(
      centerX + math.cos(angle) * radius,
      centerY + math.sin(angle) * radius,
    );
  }
}

extension BuildContextExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Light [ColorScheme] made with FlexColorScheme v8.1.1.
/// Requires Flutter 3.22.0 or later.
ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF202020),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFD1D1D1),
  onPrimaryContainer: Color(0xFF000000),
  primaryFixed: Color(0xFFCFCFCF),
  primaryFixedDim: Color(0xFFA9A9A9),
  onPrimaryFixed: Color(0xFF000000),
  onPrimaryFixedVariant: Color(0xFF000000),
  secondary: Color(0xFF777777),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFC6C6C6),
  onSecondaryContainer: Color(0xFF000000),
  secondaryFixed: Color(0xFFE1E1E1),
  secondaryFixedDim: Color(0xFFC4C4C4),
  onSecondaryFixed: Color(0xFF323232),
  onSecondaryFixedVariant: Color(0xFF3A3A3A),
  tertiary: Color(0xFF454545),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFB9B9B9),
  onTertiaryContainer: Color(0xFF000000),
  tertiaryFixed: Color(0xFFD7D7D7),
  tertiaryFixedDim: Color(0xFFB4B4B4),
  onTertiaryFixed: Color(0xFF0F0F0F),
  onTertiaryFixedVariant: Color(0xFF171717),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF000000),
  surface: Color(0xFFFCFCFC),
  onSurface: Color(0xFF111111),
  surfaceDim: Color(0xFFE0E0E0),
  surfaceBright: Color(0xFFFDFDFD),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFF8F8F8),
  surfaceContainer: Color(0xFFF3F3F3),
  surfaceContainerHigh: Color(0xFFEDEDED),
  surfaceContainerHighest: Color(0xFFE7E7E7),
  onSurfaceVariant: Color(0xFF393939),
  outline: Color(0xFF919191),
  outlineVariant: Color(0xFFD1D1D1),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF2A2A2A),
  onInverseSurface: Color(0xFFF1F1F1),
  inversePrimary: Color(0xFFA0A0A0),
  surfaceTint: Color(0xFF202020),
);

/// Dark [ColorScheme] made with FlexColorScheme v8.1.1.
/// Requires Flutter 3.22.0 or later.
ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFF0F0F0),
  onPrimary: Color(0xFF000000),
  primaryContainer: Color(0xFF474747),
  onPrimaryContainer: Color(0xFFFFFFFF),
  primaryFixed: Color(0xFFCFCFCF),
  primaryFixedDim: Color(0xFFA9A9A9),
  onPrimaryFixed: Color(0xFF000000),
  onPrimaryFixedVariant: Color(0xFF000000),
  secondary: Color(0xFFC6C6C6),
  onSecondary: Color(0xFF000000),
  secondaryContainer: Color(0xFF505050),
  onSecondaryContainer: Color(0xFFFFFFFF),
  secondaryFixed: Color(0xFFE1E1E1),
  secondaryFixedDim: Color(0xFFC4C4C4),
  onSecondaryFixed: Color(0xFF323232),
  onSecondaryFixedVariant: Color(0xFF3A3A3A),
  tertiary: Color(0xFFE2E2E2),
  onTertiary: Color(0xFF000000),
  tertiaryContainer: Color(0xFF616161),
  onTertiaryContainer: Color(0xFFFFFFFF),
  tertiaryFixed: Color(0xFFD7D7D7),
  tertiaryFixedDim: Color(0xFFB4B4B4),
  onTertiaryFixed: Color(0xFF0F0F0F),
  onTertiaryFixedVariant: Color(0xFF171717),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF000000),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFFFFF),
  surface: Color(0xFF080808),
  onSurface: Color(0xFFF1F1F1),
  surfaceDim: Color(0xFF060606),
  surfaceBright: Color(0xFF2C2C2C),
  surfaceContainerLowest: Color(0xFF010101),
  surfaceContainerLow: Color(0xFF0E0E0E),
  surfaceContainer: Color(0xFF151515),
  surfaceContainerHigh: Color(0xFF1D1D1D),
  surfaceContainerHighest: Color(0xFF282828),
  onSurfaceVariant: Color(0xFFCACACA),
  outline: Color(0xFF777777),
  outlineVariant: Color(0xFF414141),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFE8E8E8),
  onInverseSurface: Color(0xFF2A2A2A),
  inversePrimary: Color(0xFF6A6A6A),
  surfaceTint: Color(0xFFF0F0F0),
);

abstract class AppTheme {
  static ThemeData get lightTheme => FlexThemeData.light(
    colorScheme: lightColorScheme,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      useMaterial3Typography: true,
      useM2StyleDividerInM3: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    swapLegacyOnMaterial3: true,
  );

  static ThemeData get darkTheme => FlexThemeData.dark(
    colorScheme: darkColorScheme,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 13,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
      useMaterial3Typography: true,
      useM2StyleDividerInM3: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    swapLegacyOnMaterial3: true,
  );
}
