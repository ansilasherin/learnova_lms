import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

class CurvedNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const CurvedNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class CurvedAnimatedNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CurvedNavBarItem> items;
  final Color backgroundColor;
  final Color? barColor;
  final Gradient? activeGradient;
  final double height;
  final Duration animationDuration;
  final Curve animationCurve;

  const CurvedAnimatedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor = Colors.transparent,
    this.barColor,
    this.activeGradient = AppColors.primaryGradient,
    this.height = 68.0,
    this.animationDuration = const Duration(milliseconds: 360),
    this.animationCurve = Curves.easeInOutCubicEmphasized,
  }) : assert(items.length >= 2, 'CurvedAnimatedNavBar requires at least 2 items.');

  @override
  State<CurvedAnimatedNavBar> createState() => _CurvedAnimatedNavBarState();
}

class _CurvedAnimatedNavBarState extends State<CurvedAnimatedNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _fromPos = 0.0;
  double _toPos = 0.0;

  @override
  void initState() {
    super.initState();
    _fromPos = widget.currentIndex.toDouble();
    _toPos = widget.currentIndex.toDouble();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(begin: _fromPos, end: _toPos).animate(
      CurvedAnimation(parent: _controller, curve: widget.animationCurve),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void didUpdateWidget(CurvedAnimatedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _fromPos = _animation.value;
      _toPos = widget.currentIndex.toDouble();
      _controller.reset();
      _animation = Tween<double>(begin: _fromPos, end: _toPos).animate(
        CurvedAnimation(parent: _controller, curve: widget.animationCurve),
      );
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalHeight = widget.height + bottomPadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final itemCount = widget.items.length;
        final itemWidth = totalWidth / itemCount;

        // Current animated horizontal position of the notch center
        final currentPos = _animation.value;
        final activeCenterX = (currentPos + 0.5) * itemWidth;

        return Container(
          color: widget.backgroundColor,
          height: totalHeight + 24, // Extra space for floating active bubble
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Curved Background with CustomPainter
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: totalHeight,
                child: CustomPaint(
                  painter: _CurvedBarPainter(
                    activeCenterX: activeCenterX,
                    barColor: widget.barColor ?? AppColors.surface,
                    notchDepth: 28.0,
                    notchWidth: (itemWidth * 0.95).clamp(68.0, 78.0),
                  ),
                  size: Size(totalWidth, totalHeight),
                ),
              ),

              // 2. Floating Animated Active Bubble
              Positioned(
                left: activeCenterX - 27,
                top: 0, // Floats above the bar
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('bubble_${widget.currentIndex}'),
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: widget.activeGradient ?? AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.42),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            widget.items[widget.currentIndex].activeIcon ??
                                widget.items[widget.currentIndex].icon,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 3. Navigation Bar Items (Icons + Labels)
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomPadding,
                height: widget.height,
                child: Row(
                  children: List.generate(itemCount, (index) {
                    final isSelected = index == widget.currentIndex;
                    final item = widget.items[index];

                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          if (index != widget.currentIndex) {
                            widget.onTap(index);
                          }
                        },
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!isSelected) ...[
                                  Icon(
                                    item.icon,
                                    size: 24,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else ...[
                                  // Under the notch: show label and an active accent dot
                                  const SizedBox(height: 22),
                                  Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CurvedBarPainter extends CustomPainter {
  final double activeCenterX;
  final Color barColor;
  final double notchDepth;
  final double notchWidth;

  _CurvedBarPainter({
    required this.activeCenterX,
    required this.barColor,
    required this.notchDepth,
    required this.notchWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = activeCenterX;
    final halfWidth = notchWidth / 2; // e.g. 42.0

    final path = Path();
    path.moveTo(0, 0);

    // Left straight line to notch start
    path.lineTo(cx - halfWidth, 0);

    // Smooth Bezier Curve into and out of the notch
    path.cubicTo(
      cx - halfWidth * 0.55,
      0,
      cx - halfWidth * 0.45,
      notchDepth,
      cx,
      notchDepth,
    );
    path.cubicTo(
      cx + halfWidth * 0.45,
      notchDepth,
      cx + halfWidth * 0.55,
      0,
      cx + halfWidth,
      0,
    );

    // Right straight line to edge
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // 1. Draw smooth drop shadow
    final shadowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final shadowPath = Path();
    shadowPath.moveTo(0, 0);
    shadowPath.lineTo(cx - halfWidth, 0);
    shadowPath.cubicTo(
      cx - halfWidth * 0.55,
      0,
      cx - halfWidth * 0.45,
      notchDepth,
      cx,
      notchDepth,
    );
    shadowPath.cubicTo(
      cx + halfWidth * 0.45,
      notchDepth,
      cx + halfWidth * 0.55,
      0,
      cx + halfWidth,
      0,
    );
    shadowPath.lineTo(size.width, 0);
    shadowPath.lineTo(size.width, size.height);
    shadowPath.lineTo(0, size.height);
    shadowPath.close();

    canvas.save();
    canvas.translate(0, -3);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();

    // 2. Draw solid surface
    final fillPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Draw subtle top border stroke for refined elevation
    final strokePaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final topStrokePath = Path();
    topStrokePath.moveTo(0, 0);
    topStrokePath.lineTo(cx - halfWidth, 0);
    topStrokePath.cubicTo(
      cx - halfWidth * 0.55,
      0,
      cx - halfWidth * 0.45,
      notchDepth,
      cx,
      notchDepth,
    );
    topStrokePath.cubicTo(
      cx + halfWidth * 0.45,
      notchDepth,
      cx + halfWidth * 0.55,
      0,
      cx + halfWidth,
      0,
    );
    topStrokePath.lineTo(size.width, 0);

    canvas.drawPath(topStrokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedBarPainter oldDelegate) {
    return oldDelegate.activeCenterX != activeCenterX ||
        oldDelegate.barColor != barColor ||
        oldDelegate.notchDepth != notchDepth ||
        oldDelegate.notchWidth != notchWidth;
  }
}
