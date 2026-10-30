import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

/// Original geometric mark: two overlapping "speech" circles, one per answer colour.
class MirthMixMark extends StatelessWidget {
  const MirthMixMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = MmPalette.of(context);
    return ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: _MarkPainter(p.optionA, p.optionB, p.accent)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.a, this.b, this.spark);

  final Color a;
  final Color b;
  final Color spark;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.34;
    canvas.drawCircle(Offset(size.width * 0.36, size.height * 0.56), r, Paint()..color = a);
    canvas.drawCircle(Offset(size.width * 0.64, size.height * 0.44), r, Paint()..color = b.withValues(alpha: 0.88));
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.14), size.width * 0.1, Paint()..color = spark);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.a != a || old.b != b || old.spark != spark;
}

class MirthMixWordmark extends StatelessWidget {
  const MirthMixWordmark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'MirthMix',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MirthMixMark(size: size * 1.2),
            const SizedBox(width: MmSpace.s2),
            Text(
              'MirthMix',
              style: TextStyle(fontFamily: MmFont.display, fontWeight: FontWeight.w700, fontSize: size),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rounded card filled with the brand gradient. Text on it is white (contrast tested in tokens).
class GradientPanel extends StatelessWidget {
  const GradientPanel({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(MmSpace.s6)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: MmPalette.of(context).gradient,
        borderRadius: BorderRadius.circular(MmRadius.xl),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(MmRadius.xl),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
