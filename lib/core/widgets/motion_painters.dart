import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:stretchnow/core/models/stretch_model.dart';

/// Renders an articulated, smooth 2D exercise demonstration for all 12 moves.
class ExerciseMotionPainter extends CustomPainter {
  final ExerciseMotionId motionId;
  final MotionCue cue;
  final double progress;
  final Color primaryColor;
  final Color accentColor;
  final bool isDark;
  final bool compact;
  final bool isPreview;

  ExerciseMotionPainter({
    required this.motionId,
    required this.cue,
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
    required this.isDark,
    this.compact = false,
    this.isPreview = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final ox = (size.width - side) / 2;
    final oy = (size.height - side) / 2;
    final s = (side / 240.0).clamp(0.32, 1.5);

    Offset pt(double nx, double ny) => Offset(ox + nx * side, oy + ny * side);

    final farColor = Color.lerp(
      primaryColor,
      isDark ? const Color(0xFF0F1016) : Colors.white,
      0.48,
    )!;
    final matColor = (isDark ? Colors.white : primaryColor).withValues(
      alpha: isDark ? 0.11 : 0.12,
    );
    final guideColor = accentColor.withValues(alpha: compact ? 0.45 : 0.72);
    final shadowColor =
        (isDark ? Colors.black : primaryColor).withValues(alpha: isDark ? 0.35 : 0.14);

    final ctx = _PaintContext(
      canvas: canvas,
      pt: pt,
      side: side,
      s: s,
      primary: primaryColor,
      far: farColor,
      accent: accentColor,
      matColor: matColor,
      guideColor: guideColor,
      shadowColor: shadowColor,
      isDark: isDark,
      compact: compact,
      isPreview: isPreview,
    );

    switch (motionId) {
      case ExerciseMotionId.spinalTwist:
        _paintSpinalTwist(ctx, progress, cue);
      case ExerciseMotionId.hollowBodyHold:
        _paintHollowBodyHold(ctx, progress, cue);
      case ExerciseMotionId.hamstringBridge:
        _paintHamstringBridge(ctx, progress);
      case ExerciseMotionId.proneYtw:
        _paintProneYtw(ctx, progress, cue);
      case ExerciseMotionId.pushUps:
        _paintPushUps(ctx, progress, cue);
      case ExerciseMotionId.standardPlank:
        _paintStandardPlank(ctx, progress);
      case ExerciseMotionId.childsPoseToCobra:
        _paintChildsPoseToCobra(ctx, progress);
      case ExerciseMotionId.neckRotations:
        _paintNeckRotations(ctx, progress, cue);
      case ExerciseMotionId.crossoverToeTouch:
        _paintCrossoverToeTouch(ctx, progress);
      case ExerciseMotionId.itBandStretch:
        _paintItBandStretch(ctx, progress, cue);
      case ExerciseMotionId.skippingScissors:
        _paintSkippingScissors(ctx, progress);
      case ExerciseMotionId.squats:
        _paintSquats(ctx, progress);
    }
  }

  @override
  bool shouldRepaint(covariant ExerciseMotionPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.motionId != motionId ||
        oldDelegate.cue != cue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.compact != compact;
  }
}

class _PaintContext {
  final Canvas canvas;
  final Offset Function(double, double) pt;
  final double side;
  final double s;
  final Color primary;
  final Color far;
  final Color accent;
  final Color matColor;
  final Color guideColor;
  final Color shadowColor;
  final bool isDark;
  final bool compact;
  final bool isPreview;

  _PaintContext({
    required this.canvas,
    required this.pt,
    required this.side,
    required this.s,
    required this.primary,
    required this.far,
    required this.accent,
    required this.matColor,
    required this.guideColor,
    required this.shadowColor,
    required this.isDark,
    required this.compact,
    required this.isPreview,
  });

  void drawFloorMat({double y = 0.785, double left = 0.08, double right = 0.92}) {
    final p1 = pt(left, y);
    final p2 = pt(right, y);
    final h = 8.0 * s;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(p1.dx, p1.dy - h / 2, p2.dx, p2.dy + h / 2),
      Radius.circular(h / 2),
    );
    canvas.drawRRect(rect, Paint()..color = matColor);
  }

  void drawVerticalMat({
    double left = 0.31,
    double right = 0.69,
    double top = 0.09,
    double bottom = 0.91,
  }) {
    final tl = pt(left, top);
    final br = pt(right, bottom);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(tl.dx, tl.dy, br.dx, br.dy),
        Radius.circular(18 * s),
      ),
      Paint()..color = matColor,
    );
  }

  void drawFloorShadow({
    double cx = 0.50,
    double y = 0.83,
    double rx = 0.16,
    double ry = 0.025,
  }) {
    final c = pt(cx, y);
    canvas.drawOval(
      Rect.fromCenter(
        center: c,
        width: rx * 2 * side,
        height: ry * 2 * side,
      ),
      Paint()..color = shadowColor,
    );
  }

  void drawLimb(Offset a, Offset b, double thickness, Color color) {
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = thickness * s
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void drawCurvedSpine(
    Offset hip,
    Offset control,
    Offset shoulder,
    double thickness,
    Color color,
  ) {
    final path = Path()
      ..moveTo(hip.dx, hip.dy)
      ..quadraticBezierTo(control.dx, control.dy, shoulder.dx, shoulder.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = thickness * s
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void drawHead(
    Offset center, {
    double radius = 13.5,
    Color? color,
    double yaw = 0.0,
    double tilt = 0.0,
    bool showDirectionDot = false,
  }) {
    final c = color ?? primary;
    final r = radius * s;
    canvas.drawCircle(center, r, Paint()..color = c);
    if (showDirectionDot) {
      final featureColor =
          isDark ? const Color(0xFF14131A) : Colors.white.withValues(alpha: 0.9);
      final cosT = math.cos(tilt);
      final sinT = math.sin(tilt);
      Offset rot(double lx, double ly) => Offset(
            center.dx + lx * cosT - ly * sinT,
            center.dy + lx * sinT + ly * cosT,
          );

      final noseLocalX = yaw * r * 0.58;
      canvas.drawCircle(
        rot(noseLocalX, r * 0.06),
        2.3 * s,
        Paint()..color = featureColor,
      );
      // Subtle eye pair
      final eyeOffset = 3.6 * s * (1 - yaw.abs() * 0.45);
      canvas.drawCircle(
        rot(noseLocalX - eyeOffset, -r * 0.16),
        1.5 * s,
        Paint()..color = featureColor,
      );
      canvas.drawCircle(
        rot(noseLocalX + eyeOffset, -r * 0.16),
        1.5 * s,
        Paint()..color = featureColor,
      );
    }
  }

  void drawJoint(Offset p, double radius, [Color? color]) {
    if (compact) return;
    canvas.drawCircle(
      p,
      radius * s,
      Paint()..color = (color ?? accent).withValues(alpha: 0.85),
    );
  }

  void drawGlowBand(Offset a, Offset b, double width) {
    if (compact) return;
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = accent.withValues(alpha: 0.28)
        ..strokeWidth = width * s
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void drawCurvedArrow(
    Offset center,
    double rx,
    double ry,
    double startAngle,
    double sweepAngle,
  ) {
    if (compact) return;
    final rect = Rect.fromCenter(
      center: center,
      width: rx * 2 * side,
      height: ry * 2 * side,
    );
    final paint = Paint()
      ..color = guideColor
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    // Arrowhead at end of arc
    final endAngle = startAngle + sweepAngle;
    final tip = Offset(
      center.dx + rx * side * math.cos(endAngle),
      center.dy + ry * side * math.sin(endAngle),
    );
    final tangentAngle =
        endAngle + (sweepAngle >= 0 ? math.pi / 2 : -math.pi / 2);
    final headLen = 6.5 * s;
    for (final spread in [-0.55, 0.55]) {
      final wing = Offset(
        tip.dx - headLen * math.cos(tangentAngle + spread),
        tip.dy - headLen * math.sin(tangentAngle + spread),
      );
      canvas.drawLine(tip, wing, paint);
    }
  }

  void drawStageLetter(String letter, Offset pos) {
    if (compact) return;
    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          color: accent.withValues(alpha: 0.82),
          fontSize: 24 * s,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }
}

double _easePingPong(double t) {
  final tri = t <= 0.5 ? t * 2.0 : (1.0 - t) * 2.0;
  return Curves.easeInOut.transform(tri.clamp(0.0, 1.0));
}

double _easeInOut(double t) => Curves.easeInOut.transform(t.clamp(0.0, 1.0));

Offset _lerp(Offset a, Offset b, double t) => Offset.lerp(a, b, t)!;

// -----------------------------------------------------------------------------
// 1. SPINAL TWIST (Elevated 3/4 overhead view on vertical mat)
// -----------------------------------------------------------------------------
void _paintSpinalTwist(_PaintContext ctx, double t, MotionCue cue) {
  ctx.drawVerticalMat(left: 0.30, right: 0.70, top: 0.08, bottom: 0.90);

  double kneeDir; // -1 = left, +1 = right
  if (cue == MotionCue.twistLeft) {
    final enter = _easeInOut((t / 0.14).clamp(0.0, 1.0));
    final breath = math.sin(t * math.pi * 8) * 0.03;
    kneeDir = -(ctx.isPreview ? _easePingPong(t) * 0.95 : enter * 0.95 + breath);
  } else if (cue == MotionCue.twistRight) {
    final enter = _easeInOut((t / 0.14).clamp(0.0, 1.0));
    final breath = math.sin(t * math.pi * 8) * 0.03;
    kneeDir = ctx.isPreview ? _easePingPong(t) * 0.95 : enter * 0.95 + breath;
  } else {
    // Full L <-> R sweep with gentle pauses on each side
    final wave = math.sin(t * math.pi * 2);
    kneeDir = wave.sign * Curves.easeInOut.transform(wave.abs());
  }

  final pt = ctx.pt;
  final head = pt(0.50, 0.20);
  final shoulderL = pt(0.39, 0.33);
  final shoulderR = pt(0.61, 0.33);
  final handL = pt(0.14, 0.36);
  final handR = pt(0.86, 0.36);
  final chest = pt(0.50, 0.34);
  final pelvis = pt(0.50 + kneeDir * 0.025, 0.54);

  // Arms out in T
  ctx.drawLimb(shoulderL, handL, 8.5, ctx.primary);
  ctx.drawLimb(shoulderR, handR, 8.5, ctx.primary);
  ctx.drawLimb(shoulderL, shoulderR, 12, ctx.primary);

  // Torso
  ctx.drawCurvedSpine(
    pelvis,
    pt(0.50 + kneeDir * 0.015, 0.45),
    chest,
    17.5,
    ctx.primary,
  );

  // Bent legs dropping together (far leg offset subtly beneath near leg)
  final kneeTop = pt(0.50 + kneeDir * 0.24, 0.62 - kneeDir.abs() * 0.02);
  final footTop = pt(0.50 + kneeDir * 0.14, 0.79);
  final kneeBot = pt(0.50 + kneeDir * 0.22, 0.65 - kneeDir.abs() * 0.02);
  final footBot = pt(0.50 + kneeDir * 0.12, 0.82);

  // Bottom leg (far)
  ctx.drawLimb(pelvis, kneeBot, 11.5, ctx.far);
  ctx.drawLimb(kneeBot, footBot, 9.5, ctx.far);
  // Top leg (near)
  ctx.drawLimb(pelvis, kneeTop, 12.0, ctx.primary);
  ctx.drawLimb(kneeTop, footTop, 10.0, ctx.primary);

  // Neck & head looking gently away from knees
  ctx.drawLimb(chest, head, 8.5, ctx.primary);
  ctx.drawHead(
    head,
    radius: 13.0,
    yaw: -kneeDir * 0.45,
    showDirectionDot: !ctx.compact,
  );

  // Motion guide arc
  if (kneeDir.abs() > 0.18) {
    final arcSweep = kneeDir > 0 ? 0.85 : -0.85;
    ctx.drawCurvedArrow(pt(0.50, 0.57), 0.24, 0.10, math.pi * 0.5 - arcSweep * 0.4, arcSweep);
  }
}

// -----------------------------------------------------------------------------
// 2. HOLLOW BODY HOLD (Side profile on horizontal mat)
// -----------------------------------------------------------------------------
void _paintHollowBodyHold(_PaintContext ctx, double t, MotionCue cue) {
  ctx.drawFloorMat(y: 0.785);

  double holdAmt;
  if (cue == MotionCue.restFlat) {
    holdAmt = 0.0;
  } else if (ctx.isPreview) {
    // Smoothly lift, hold steady, lower
    if (t < 0.2) {
      holdAmt = _easeInOut(t / 0.2);
    } else if (t < 0.78) {
      holdAmt = 1.0;
    } else {
      holdAmt = 1.0 - _easeInOut((t - 0.78) / 0.22);
    }
  } else {
    final enter = _easeInOut((t / 0.12).clamp(0.0, 1.0));
    holdAmt = enter;
  }

  final breath = math.sin(t * math.pi * 8) * 0.005;
  final pt = ctx.pt;

  // Flat rest vs banana hollow dish
  final lowBack = pt(0.47, 0.75 + (1 - holdAmt) * 0.005);
  final shoulders = _lerp(pt(0.30, 0.745), pt(0.31, 0.625 + breath), holdAmt);
  final head = _lerp(pt(0.21, 0.725), pt(0.23, 0.56 + breath), holdAmt);
  final elbow = _lerp(pt(0.21, 0.755), pt(0.19, 0.54 + breath), holdAmt);
  final hand = _lerp(pt(0.12, 0.76), pt(0.10, 0.48 + breath), holdAmt);

  final pelvis = _lerp(pt(0.57, 0.75), pt(0.57, 0.735), holdAmt);
  final knee = _lerp(pt(0.71, 0.75), pt(0.71, 0.685 - breath), holdAmt);
  final ankle = _lerp(pt(0.84, 0.75), pt(0.85, 0.615 - breath), holdAmt);

  // Far arm & far leg
  ctx.drawLimb(shoulders, elbow, 7.5, ctx.far);
  ctx.drawLimb(elbow, hand, 6.5, ctx.far);
  ctx.drawLimb(pelvis, knee, 11.5, ctx.far);
  ctx.drawLimb(knee, ankle, 9.5, ctx.far);

  // Lower-back contact glow when engaged
  if (holdAmt > 0.5) {
    ctx.drawGlowBand(pt(0.41, 0.77), pt(0.55, 0.77), 7.5);
  }

  // Spine + pelvis
  ctx.drawCurvedSpine(pelvis, lowBack, shoulders, 16.5, ctx.primary);

  // Near leg
  ctx.drawLimb(pelvis, knee, 12.0, ctx.primary);
  ctx.drawLimb(knee, ankle, 9.8, ctx.primary);

  // Neck, head & near arm overhead
  ctx.drawLimb(shoulders, head, 8.0, ctx.primary);
  ctx.drawHead(head, radius: 12.5);
  ctx.drawLimb(shoulders, elbow, 8.2, ctx.primary);
  ctx.drawLimb(elbow, hand, 7.0, ctx.primary);
}

// -----------------------------------------------------------------------------
// 3. HAMSTRING BRIDGE (Side profile on horizontal mat)
// -----------------------------------------------------------------------------
void _paintHamstringBridge(_PaintContext ctx, double t) {
  ctx.drawFloorMat(y: 0.785);

  // Smooth lift, brief top squeeze, controlled lower
  double lift;
  if (t < 0.36) {
    lift = _easeInOut(t / 0.36);
  } else if (t < 0.56) {
    lift = 1.0;
  } else {
    lift = 1.0 - _easeInOut((t - 0.56) / 0.44);
  }

  final pt = ctx.pt;
  final head = pt(0.19, 0.725);
  final shoulders = pt(0.28, 0.745);
  final foot = pt(0.77, 0.76);
  final knee = _lerp(pt(0.65, 0.49), pt(0.66, 0.46), lift);
  final hips = _lerp(pt(0.51, 0.75), pt(0.49, 0.52), lift);
  final hand = pt(0.53, 0.765);

  // Far leg
  ctx.drawLimb(hips, knee, 12.0, ctx.far);
  ctx.drawLimb(knee, foot, 10.0, ctx.far);

  if (lift > 0.35) {
    ctx.drawGlowBand(hips, knee, 8.0);
  }

  // Spine from hips to anchored shoulders
  ctx.drawCurvedSpine(
    hips,
    _lerp(pt(0.40, 0.75), pt(0.39, 0.635), lift),
    shoulders,
    16.5,
    ctx.primary,
  );

  // Near leg
  ctx.drawLimb(hips, knee, 12.5, ctx.primary);
  ctx.drawLimb(knee, foot, 10.2, ctx.primary);

  // Arm resting on mat
  ctx.drawLimb(shoulders, hand, 8.0, ctx.primary);

  // Neck & head
  ctx.drawLimb(shoulders, head, 8.5, ctx.primary);
  ctx.drawHead(head, radius: 12.5);

  // Upward motion cue
  if (t < 0.50) {
    ctx.drawCurvedArrow(pt(0.49, 0.64), 0.05, 0.08, math.pi * 0.75, -math.pi * 0.5);
  }
}

// -----------------------------------------------------------------------------
// 4. PRONE Y-T-W RAISES (Elevated overhead prone view on vertical mat)
// -----------------------------------------------------------------------------
void _paintProneYtw(_PaintContext ctx, double t, MotionCue cue) {
  ctx.drawVerticalMat(left: 0.31, right: 0.69, top: 0.14, bottom: 0.92);

  String activeShape;
  double localT;
  if (cue == MotionCue.proneY) {
    activeShape = 'Y';
    localT = t;
  } else if (cue == MotionCue.proneT) {
    activeShape = 'T';
    localT = t;
  } else if (cue == MotionCue.proneW) {
    activeShape = 'W';
    localT = t;
  } else {
    if (t < 1 / 3) {
      activeShape = 'Y';
      localT = t * 3.0;
    } else if (t < 2 / 3) {
      activeShape = 'T';
      localT = (t - 1 / 3) * 3.0;
    } else {
      activeShape = 'W';
      localT = (t - 2 / 3) * 3.0;
    }
  }

  final lift = _easePingPong(localT);
  final pt = ctx.pt;

  final head = pt(0.50, 0.25 - lift * 0.015);
  final shoulderL = pt(0.41, 0.35 - lift * 0.012);
  final shoulderR = pt(0.59, 0.35 - lift * 0.012);
  final chest = pt(0.50, 0.35 - lift * 0.012);
  final pelvis = pt(0.50, 0.57);
  final footL = pt(0.44, 0.87);
  final footR = pt(0.56, 0.87);

  // Legs extended on mat
  ctx.drawLimb(pt(0.46, 0.57), footL, 11.5, ctx.far);
  ctx.drawLimb(pt(0.54, 0.57), footR, 11.5, ctx.far);

  // Torso
  ctx.drawLimb(pelvis, chest, 18.0, ctx.primary);
  ctx.drawLimb(shoulderL, shoulderR, 12.0, ctx.primary);

  // Scapula squeeze glow
  if (lift > 0.35) {
    ctx.drawGlowBand(shoulderL, shoulderR, 9.0);
  }

  // Arms forming Y, T, or W
  late final Offset elbowL, handL, elbowR, handR;
  final dy = lift * 0.032;
  if (activeShape == 'Y') {
    elbowL = pt(0.34, 0.24 - dy * 0.6);
    handL = pt(0.26, 0.14 - dy);
    elbowR = pt(0.66, 0.24 - dy * 0.6);
    handR = pt(0.74, 0.14 - dy);
  } else if (activeShape == 'T') {
    elbowL = pt(0.28, 0.35 - dy * 0.6);
    handL = pt(0.14, 0.35 - dy);
    elbowR = pt(0.72, 0.35 - dy * 0.6);
    handR = pt(0.86, 0.35 - dy);
  } else {
    // W shape: elbows tucked back toward ribs, hands forward
    elbowL = pt(0.32, 0.44 - dy * 0.6);
    handL = pt(0.29, 0.26 - dy);
    elbowR = pt(0.68, 0.44 - dy * 0.6);
    handR = pt(0.71, 0.26 - dy);
  }

  ctx.drawLimb(shoulderL, elbowL, 8.8, ctx.primary);
  ctx.drawLimb(elbowL, handL, 7.6, ctx.primary);
  ctx.drawLimb(shoulderR, elbowR, 8.8, ctx.primary);
  ctx.drawLimb(elbowR, handR, 7.6, ctx.primary);
  ctx.drawJoint(handL, 4.0);
  ctx.drawJoint(handR, 4.0);

  // Head
  ctx.drawHead(head, radius: 12.5);
  ctx.drawStageLetter(activeShape, pt(0.83, 0.18));
}

// -----------------------------------------------------------------------------
// 5. PUSH-UPS (Knees down -> Standard -> Feet elevated)
// -----------------------------------------------------------------------------
void _paintPushUps(_PaintContext ctx, double t, MotionCue cue) {
  ctx.drawFloorMat(y: 0.785);

  final dip = _easePingPong(t);
  final pt = ctx.pt;

  final hand = pt(0.71, 0.76);
  final shoulders = _lerp(pt(0.69, 0.48), pt(0.69, 0.675), dip);
  final elbow = _lerp(pt(0.69, 0.62), pt(0.58, 0.66), dip);
  final head = shoulders + Offset(0.085 * ctx.side, -0.055 * ctx.side);

  late final Offset anchorPivot;
  Offset? lowerShinEnd;

  if (cue == MotionCue.pushupKnees) {
    anchorPivot = pt(0.33, 0.755); // knees on mat
    lowerShinEnd = pt(0.21, 0.64); // calves angled up
  } else if (cue == MotionCue.pushupElevated) {
    // Draw elevated bench/step block at left
    final boxTl = pt(0.09, 0.59);
    final boxBr = pt(0.25, 0.78);
    ctx.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(boxTl.dx, boxTl.dy, boxBr.dx, boxBr.dy),
        Radius.circular(6 * ctx.s),
      ),
      Paint()..color = ctx.accent.withValues(alpha: 0.25),
    );
    anchorPivot = pt(0.20, 0.575); // feet elevated on step
  } else {
    anchorPivot = pt(0.18, 0.755); // toes on mat
  }

  final hips = _lerp(anchorPivot, shoulders, 0.48);

  // Far arm behind torso
  ctx.drawLimb(shoulders, elbow + Offset(5 * ctx.s, -2 * ctx.s), 7.8, ctx.far);
  ctx.drawLimb(elbow + Offset(5 * ctx.s, -2 * ctx.s), hand, 7.0, ctx.far);

  // Legs + torso straight plank alignment
  if (lowerShinEnd != null) {
    ctx.drawLimb(anchorPivot, lowerShinEnd, 9.5, ctx.far);
    ctx.drawLimb(anchorPivot, lowerShinEnd, 10.0, ctx.primary);
  }
  ctx.drawLimb(anchorPivot, hips, 11.5, ctx.primary);
  ctx.drawLimb(hips, shoulders, 16.0, ctx.primary);

  // Neck & head
  ctx.drawLimb(shoulders, head, 8.2, ctx.primary);
  ctx.drawHead(head, radius: 12.0);

  // Near arm
  ctx.drawLimb(shoulders, elbow, 8.5, ctx.primary);
  ctx.drawLimb(elbow, hand, 7.6, ctx.primary);
}

// -----------------------------------------------------------------------------
// 6. STANDARD PLANK (Side profile on forearms & toes)
// -----------------------------------------------------------------------------
void _paintStandardPlank(_PaintContext ctx, double t) {
  ctx.drawFloorMat(y: 0.785);

  final breath = math.sin(t * math.pi * 4) * 0.008;
  final pt = ctx.pt;

  final toes = pt(0.17, 0.755);
  final knees = pt(0.31, 0.665);
  final hips = pt(0.45, 0.57 + breath * 0.5);
  final shoulders = pt(0.66, 0.55 + breath);
  final elbow = pt(0.66, 0.755);
  final hand = pt(0.78, 0.76);
  final head = pt(0.77, 0.50 + breath);

  // Far leg & arm
  ctx.drawLimb(toes, knees, 9.8, ctx.far);
  ctx.drawLimb(knees, hips, 11.5, ctx.far);
  ctx.drawLimb(shoulders, elbow + Offset(4 * ctx.s, 0), 7.8, ctx.far);

  // Core alignment glow
  ctx.drawGlowBand(hips, shoulders, 10.0);

  // Near leg & torso
  ctx.drawLimb(toes, knees, 10.2, ctx.primary);
  ctx.drawLimb(knees, hips, 12.0, ctx.primary);
  ctx.drawLimb(hips, shoulders, 16.5, ctx.primary);

  // Near forearm
  ctx.drawLimb(shoulders, elbow, 8.6, ctx.primary);
  ctx.drawLimb(elbow, hand, 8.0, ctx.primary);

  // Neck & head looking softly down toward hands
  ctx.drawLimb(shoulders, head, 8.2, ctx.primary);
  ctx.drawHead(head, radius: 12.2);
}

// -----------------------------------------------------------------------------
// 7. KNEELING CHILD'S POSE TO COBRA (Smooth slide flow on mat)
// -----------------------------------------------------------------------------
void _paintChildsPoseToCobra(_PaintContext ctx, double t) {
  ctx.drawFloorMat(y: 0.785);

  final flow = _easePingPong(t); // 0 = Child's Pose, 1 = Cobra
  final pt = ctx.pt;

  final foot = _lerp(pt(0.17, 0.755), pt(0.12, 0.755), flow);
  final knee = _lerp(pt(0.32, 0.755), pt(0.28, 0.755), flow);
  final hips = _lerp(pt(0.23, 0.60), pt(0.46, 0.735), flow);
  final spineCtrl = _lerp(pt(0.36, 0.59), pt(0.61, 0.655), flow);
  final shoulders = _lerp(pt(0.49, 0.665), pt(0.66, 0.455), flow);
  final head = _lerp(pt(0.55, 0.70), pt(0.71, 0.34), flow);
  final hand = _lerp(pt(0.79, 0.76), pt(0.69, 0.76), flow);
  final elbow = _lerp(pt(0.65, 0.735), pt(0.68, 0.61), flow);

  // Far leg & arm
  ctx.drawLimb(foot, knee, 9.5, ctx.far);
  ctx.drawLimb(knee, hips, 11.2, ctx.far);
  ctx.drawLimb(shoulders, elbow, 7.6, ctx.far);
  ctx.drawLimb(elbow, hand, 7.0, ctx.far);

  // Near leg
  ctx.drawLimb(foot, knee, 10.0, ctx.primary);
  ctx.drawLimb(knee, hips, 11.8, ctx.primary);

  // Flowing spine curve
  ctx.drawCurvedSpine(hips, spineCtrl, shoulders, 16.5, ctx.primary);

  // Near arm
  ctx.drawLimb(shoulders, elbow, 8.4, ctx.primary);
  ctx.drawLimb(elbow, hand, 7.6, ctx.primary);

  // Neck & head
  ctx.drawLimb(shoulders, head, 8.0, ctx.primary);
  ctx.drawHead(head, radius: 12.0);

  if (flow > 0.15 && flow < 0.85) {
    ctx.drawCurvedArrow(pt(0.56, 0.52), 0.16, 0.14, -math.pi * 0.85, math.pi * 0.5);
  }
}

// -----------------------------------------------------------------------------
// 8. NECK ROTATIONS (Front upper-body bust view)
// -----------------------------------------------------------------------------
void _paintNeckRotations(_PaintContext ctx, double t, MotionCue cue) {
  final pt = ctx.pt;

  double yaw = 0.0; // -1 left, +1 right
  double tilt = 0.0; // -1 tilt left, +1 tilt right
  double pitchY = 0.0; // vertical nod offset for roll
  bool showRollHalo = false;

  if (cue == MotionCue.neckTurnRight) {
    yaw = ctx.isPreview ? _easePingPong(t) * 0.95 : _easeInOut((t / 0.25).clamp(0.0, 1.0)) * 0.95;
  } else if (cue == MotionCue.neckTurnLeft) {
    yaw = -(ctx.isPreview ? _easePingPong(t) * 0.95 : _easeInOut((t / 0.25).clamp(0.0, 1.0)) * 0.95);
  } else if (cue == MotionCue.neckTiltRight) {
    tilt = ctx.isPreview ? _easePingPong(t) * 0.78 : _easeInOut((t / 0.25).clamp(0.0, 1.0)) * 0.78;
  } else if (cue == MotionCue.neckTiltLeft) {
    tilt = -(ctx.isPreview ? _easePingPong(t) * 0.78 : _easeInOut((t / 0.25).clamp(0.0, 1.0)) * 0.78);
  } else if (cue == MotionCue.neckRoll) {
    final angle = t * math.pi * 2;
    yaw = math.sin(angle) * 0.62;
    pitchY = math.cos(angle) * 0.032; // +front -> 0 right -> -back -> 0 left
    tilt = math.sin(angle) * 0.36;
    showRollHalo = true;
  } else {
    // Full 5-stage preview loop
    if (t < 0.18) {
      yaw = _easePingPong(t / 0.18) * 0.95;
    } else if (t < 0.36) {
      yaw = -_easePingPong((t - 0.18) / 0.18) * 0.95;
    } else if (t < 0.54) {
      tilt = _easePingPong((t - 0.36) / 0.18) * 0.78;
    } else if (t < 0.72) {
      tilt = -_easePingPong((t - 0.54) / 0.18) * 0.78;
    } else {
      final rollT = (t - 0.72) / 0.28;
      final angle = rollT * math.pi * 2;
      yaw = math.sin(angle) * 0.62;
      pitchY = math.cos(angle) * 0.032;
      tilt = math.sin(angle) * 0.36;
      showRollHalo = true;
    }
  }

  // Draw relaxed upper chest & shoulders
  final shoulderL = pt(0.28, 0.66);
  final shoulderR = pt(0.72, 0.66);
  final torsoBot = pt(0.50, 0.90);
  final neckBase = pt(0.50, 0.61);

  ctx.drawLimb(pt(0.38, 0.90), shoulderL, 14.0, ctx.primary);
  ctx.drawLimb(pt(0.62, 0.90), shoulderR, 14.0, ctx.primary);
  ctx.drawLimb(shoulderL, shoulderR, 20.0, ctx.primary);
  ctx.drawLimb(neckBase, torsoBot, 34.0, ctx.primary);

  // Head pivot off neck base (deeper lateral tilt toward shoulder)
  final headOffset = Offset(
    math.sin(tilt) * 0.105,
    -math.cos(tilt) * 0.175 + pitchY,
  );
  final headCenter = pt(0.50 + headOffset.dx, 0.54 + headOffset.dy);

  ctx.drawLimb(neckBase, headCenter, 13.5, ctx.primary);

  // Ear cues (drawn behind/beside head)
  final earR = 4.2 * ctx.s;
  final headRadiusPx = 25.0 * ctx.s;
  final leftEarOffset = Offset(-math.cos(tilt) * headRadiusPx, -math.sin(tilt) * headRadiusPx);
  final rightEarOffset = Offset(math.cos(tilt) * headRadiusPx, math.sin(tilt) * headRadiusPx);
  ctx.canvas.drawCircle(
    headCenter + leftEarOffset * (1.0 - math.max(0.0, -yaw) * 0.4),
    earR,
    Paint()..color = ctx.far,
  );
  ctx.canvas.drawCircle(
    headCenter + rightEarOffset * (1.0 - math.max(0.0, yaw) * 0.4),
    earR,
    Paint()..color = ctx.far,
  );

  ctx.drawHead(
    headCenter,
    radius: 25.0,
    yaw: yaw,
    tilt: tilt,
    showDirectionDot: true,
  );

  if (showRollHalo) {
    ctx.drawCurvedArrow(pt(0.50, 0.36), 0.18, 0.14, 0.2, math.pi * 1.65);
  } else if (yaw.abs() > 0.2) {
    ctx.drawCurvedArrow(
      headCenter,
      0.16,
      0.06,
      yaw > 0 ? math.pi * 0.72 : math.pi * 0.28,
      yaw > 0 ? -0.9 : 0.9,
    );
  } else if (tilt.abs() > 0.12) {
    ctx.drawCurvedArrow(
      pt(0.50, 0.37),
      0.17,
      0.17,
      tilt > 0 ? -math.pi * 0.55 : -math.pi * 0.45,
      tilt > 0 ? 1.15 : -1.15,
    );
  }
}

// -----------------------------------------------------------------------------
// 9. BENDING CROSSOVER TOE TOUCH (Wide-stance bent-over windmill swing)
// -----------------------------------------------------------------------------
void _paintCrossoverToeTouch(_PaintContext ctx, double t) {
  ctx.drawFloorShadow(cx: 0.50, y: 0.85, rx: 0.24, ry: 0.022);
  final pt = ctx.pt;

  // swing = +1 -> right hand crosses over to touch left foot while left arm swings up
  // swing = -1 -> left hand crosses over to touch right foot while right arm swings up
  final swing = math.cos(t * math.pi * 2);
  final theta = swing * 2.15; // ±123 deg rotation around bent-forward torso
  final cosT = math.cos(theta);
  final sinT = math.sin(theta);

  // Wide straddle legs (screen-left = left foot, screen-right = right foot)
  final pelvis = pt(0.50, 0.50);
  final footL = pt(0.28, 0.835);
  final kneeL = pt(0.38, 0.67);
  final footR = pt(0.72, 0.835);
  final kneeR = pt(0.62, 0.67);

  ctx.drawLimb(pelvis, kneeL, 11.8, ctx.primary);
  ctx.drawLimb(kneeL, footL, 9.8, ctx.primary);
  ctx.drawLimb(pelvis, kneeR, 11.8, ctx.primary);
  ctx.drawLimb(kneeR, footR, 9.8, ctx.primary);

  // Bent-forward torso hinged at pelvis; shoulders rotate around torso axis
  final shouldersCenter = pt(0.50 - swing * 0.015, 0.49 + 0.025 * swing.abs());
  final spineCtrl = pt(0.50, 0.495);
  final head = pt(0.50 - swing * 0.02, 0.55 + 0.02 * swing.abs());

  Offset rotArm(double vx, {double yScale = 0.86}) =>
      shouldersCenter +
      Offset(vx * cosT * ctx.side, vx * sinT * yScale * ctx.side);

  // Screen-left shoulder/arm (L) starts at -x; screen-right shoulder/arm (R) starts at +x.
  // Rotating by +2.15 rad brings +x arm across front to footL (0.28, 0.81) and -x arm up (0.71, 0.18).
  // Rotating by -2.15 rad brings -x arm across front to footR (0.72, 0.81) and +x arm up (0.29, 0.18).
  final shoulderL = rotArm(-0.085, yScale: 0.72);
  final shoulderR = rotArm(0.085, yScale: 0.72);
  final handL = rotArm(-0.375, yScale: 0.98);
  final handR = rotArm(0.375, yScale: 0.98);

  // Back/upper swinging arm drawn behind torso, front crossing arm drawn in front
  if (swing >= 0) {
    ctx.drawLimb(shoulderL, handL, 7.6, ctx.far);
    ctx.drawCurvedSpine(pelvis, spineCtrl, shouldersCenter, 16.5, ctx.primary);
    ctx.drawLimb(shoulderR, shoulderL, 12.0, ctx.primary);
    ctx.drawHead(head, radius: 11.5);
    ctx.drawLimb(shoulderR, handR, 8.2, ctx.primary);
  } else {
    ctx.drawLimb(shoulderR, handR, 7.6, ctx.far);
    ctx.drawCurvedSpine(pelvis, spineCtrl, shouldersCenter, 16.5, ctx.primary);
    ctx.drawLimb(shoulderR, shoulderL, 12.0, ctx.primary);
    ctx.drawHead(head, radius: 11.5);
    ctx.drawLimb(shoulderL, handL, 8.2, ctx.primary);
  }

  ctx.drawJoint(handR, 4.0);
  ctx.drawJoint(handL, 4.0);

  if (swing.abs() < 0.7) {
    final goingRight = math.sin(t * math.pi * 2) > 0;
    ctx.drawCurvedArrow(
      pt(0.50, 0.72),
      0.16,
      0.08,
      goingRight ? math.pi * 0.75 : math.pi * 0.25,
      goingRight ? -math.pi * 0.5 : math.pi * 0.5,
    );
  }
}

// -----------------------------------------------------------------------------
// 10. LEFT & RIGHT IT BAND STRETCH (Front standing lateral C-curve)
// -----------------------------------------------------------------------------
void _paintItBandStretch(_PaintContext ctx, double t, MotionCue cue) {
  ctx.drawFloorShadow(cx: 0.50, y: 0.84, rx: 0.16, ry: 0.022);
  final pt = ctx.pt;

  late final double dir; // +1 = stretch outer right side of figure (lean left), -1 = stretch outer left side (lean right)
  late final double lean;

  if (cue == MotionCue.itBandLeft) {
    dir = 1.0;
    lean = _easePingPong(t);
  } else if (cue == MotionCue.itBandRight) {
    dir = -1.0;
    lean = _easePingPong(t);
  } else {
    dir = t < 0.5 ? 1.0 : -1.0;
    lean = _easePingPong(t < 0.5 ? t * 2.0 : (t - 0.5) * 2.0);
  }

  // Front standing leg planted; back leg crosses behind toward the lean side
  final frontFoot = pt(0.50 + dir * 0.015, 0.835);
  final frontKnee = pt(0.50 + dir * 0.01, 0.66);

  final backFoot = pt(0.50 - dir * 0.09, 0.82);
  final backKnee = pt(0.50 - dir * 0.025, 0.665);

  // Pelvis pushes out toward the stretched outer hip (+dir), torso leans opposite (-dir)
  final pelvis = pt(0.50 + dir * 0.06 * lean, 0.50);
  final spineCtrl = pt(0.50 + dir * 0.04 * lean, 0.40);
  final shoulders = pt(0.50 - dir * 0.10 * lean, 0.30 + 0.025 * lean);
  final head = pt(0.50 - dir * 0.135 * lean, 0.20 + 0.035 * lean);

  // Back crossed leg (stretched IT band along outer +dir hip)
  ctx.drawLimb(pelvis, backKnee, 11.5, ctx.far);
  ctx.drawLimb(backKnee, backFoot, 9.5, ctx.far);
  if (lean > 0.35) {
    ctx.drawGlowBand(
      pelvis + Offset(dir * 5 * ctx.s, 0),
      backKnee + Offset(dir * 3 * ctx.s, 0),
      9.0,
    );
  }

  // Front leg
  ctx.drawLimb(pelvis, frontKnee, 12.0, ctx.primary);
  ctx.drawLimb(frontKnee, frontFoot, 9.8, ctx.primary);

  // Curved torso
  ctx.drawCurvedSpine(pelvis, spineCtrl, shoulders, 16.5, ctx.primary);

  // Raised overhead arm (+dir side) arching over head toward -dir side
  final reachShoulder = shoulders + Offset(dir * 10 * ctx.s, 0);
  final reachElbow = pt(
    0.50 + dir * (0.04 - 0.09 * lean),
    0.20 - 0.04 * lean,
  );
  final reachHand = pt(
    0.50 - dir * (0.18 * lean - 0.07 * (1 - lean)),
    0.16 + 0.03 * lean,
  );

  // Resting arm sliding down hip on the lean side
  final restShoulder = shoulders + Offset(-dir * 10 * ctx.s, 0);
  final restHand = pt(0.50 - dir * (0.10 + 0.04 * lean), 0.50 + 0.03 * lean);

  ctx.drawLimb(reachShoulder, reachElbow, 8.0, ctx.primary);
  ctx.drawLimb(reachElbow, reachHand, 7.2, ctx.primary);
  ctx.drawLimb(restShoulder, restHand, 7.8, ctx.primary);

  ctx.drawLimb(shoulders, head, 8.0, ctx.primary);
  ctx.drawHead(head, radius: 12.0);
}

// -----------------------------------------------------------------------------
// 11. SKIPPING SCISSORS (Lively rhythmic front-back scissor hops)
// -----------------------------------------------------------------------------
void _paintSkippingScissors(_PaintContext ctx, double t) {
  final phase = t * math.pi * 2;
  final hop = math.sin(phase * 2).abs() * 0.055;
  final stride = math.sin(phase); // -1..+1 alternating leg scissor

  ctx.drawFloorShadow(
    cx: 0.50,
    y: 0.84,
    rx: 0.14 - hop * 0.5,
    ry: 0.020,
  );

  final pt = ctx.pt;
  final pelvis = pt(0.50, 0.49 - hop);
  final shoulders = pt(0.51, 0.29 - hop);
  final head = pt(0.52, 0.19 - hop);

  // Scissoring legs
  final nearKnee = pt(0.50 + stride * 0.11, 0.65 - hop - stride.abs() * 0.015);
  final nearFoot = pt(0.50 + stride * 0.16, 0.81 - hop - math.max(0.0, stride) * 0.03);

  final farKnee = pt(0.50 - stride * 0.11, 0.65 - hop - stride.abs() * 0.015);
  final farFoot = pt(0.50 - stride * 0.16, 0.81 - hop - math.max(0.0, -stride) * 0.03);

  // Far arm swings opposite to far leg
  final farElbow = pt(0.49 + stride * 0.08, 0.40 - hop);
  final farHand = pt(0.53 + stride * 0.13, 0.37 - hop);

  final nearElbow = pt(0.49 - stride * 0.08, 0.40 - hop);
  final nearHand = pt(0.53 - stride * 0.13, 0.37 - hop);

  // Far limbs
  ctx.drawLimb(pelvis, farKnee, 11.5, ctx.far);
  ctx.drawLimb(farKnee, farFoot, 9.5, ctx.far);
  ctx.drawLimb(shoulders, farElbow, 7.6, ctx.far);
  ctx.drawLimb(farElbow, farHand, 6.8, ctx.far);

  // Torso
  ctx.drawLimb(pelvis, shoulders, 16.0, ctx.primary);

  // Near leg & arm
  ctx.drawLimb(pelvis, nearKnee, 12.0, ctx.primary);
  ctx.drawLimb(nearKnee, nearFoot, 9.8, ctx.primary);
  ctx.drawLimb(shoulders, nearElbow, 8.2, ctx.primary);
  ctx.drawLimb(nearElbow, nearHand, 7.2, ctx.primary);

  // Head
  ctx.drawLimb(shoulders, head, 8.0, ctx.primary);
  ctx.drawHead(head, radius: 12.0);
}

// -----------------------------------------------------------------------------
// 12. SQUATS (Side-3/4 standing squat with forward counterbalance arms)
// -----------------------------------------------------------------------------
void _paintSquats(_PaintContext ctx, double t) {
  ctx.drawFloorShadow(cx: 0.50, y: 0.84, rx: 0.16, ry: 0.024);

  // Smooth descent, crisp bottom beat, strong stand-up
  double d;
  if (t < 0.42) {
    d = _easeInOut(t / 0.42);
  } else if (t < 0.56) {
    d = 1.0;
  } else {
    d = 1.0 - _easeInOut((t - 0.56) / 0.44);
  }

  final pt = ctx.pt;
  final farFoot = pt(0.54, 0.805);
  final nearFoot = pt(0.47, 0.835);

  final farKnee = _lerp(pt(0.53, 0.65), pt(0.61, 0.65), d);
  final nearKnee = _lerp(pt(0.48, 0.66), pt(0.56, 0.665), d);

  final hips = _lerp(pt(0.47, 0.49), pt(0.36, 0.655), d);
  final shoulders = _lerp(pt(0.48, 0.29), pt(0.47, 0.445), d);
  final head = _lerp(pt(0.49, 0.19), pt(0.49, 0.34), d);

  final farHand = _lerp(pt(0.52, 0.48), pt(0.69, 0.42), d);
  final nearHand = _lerp(pt(0.46, 0.49), pt(0.64, 0.44), d);

  // Far leg & arm
  ctx.drawLimb(hips, farKnee, 11.8, ctx.far);
  ctx.drawLimb(farKnee, farFoot, 9.6, ctx.far);
  ctx.drawLimb(shoulders, farHand, 7.8, ctx.far);

  // Proud upright-angled torso
  ctx.drawLimb(hips, shoulders, 16.8, ctx.primary);

  // Near leg
  ctx.drawLimb(hips, nearKnee, 12.2, ctx.primary);
  ctx.drawLimb(nearKnee, nearFoot, 10.0, ctx.primary);

  // Neck & head
  ctx.drawLimb(shoulders, head, 8.2, ctx.primary);
  ctx.drawHead(head, radius: 12.2);

  // Near arm
  ctx.drawLimb(shoulders, nearHand, 8.2, ctx.primary);
}
