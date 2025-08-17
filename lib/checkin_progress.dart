import 'package:flutter/material.dart';

class CheckinProgress extends StatelessWidget {
  final List<dynamic>? checklist;

  const CheckinProgress({super.key, required this.checklist});

  @override
  Widget build(BuildContext context) {
    if (checklist == null || checklist!.isEmpty) {
      return const Text("No checkpoints");
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = checklist!.length;
        final maxWidth = constraints.maxWidth;
        final circleDiameter = (maxWidth / count) - 6;
        final radius = (circleDiameter / 2).clamp(8.0, 15.0);

        final completedCount = checklist!
            .where((entry) => entry?['checkin_datetime'] != null)
            .length;

        return SizedBox(
          height: radius * 2,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ChecklistProgressLinePainter(
                    circleCount: count,
                    radius: radius,
                    width: maxWidth,
                    completedCount: completedCount,
                    completedColor: Colors.green,
                    remainingColor: Colors.grey.shade400,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: checklist!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controlNum = index + 1;
                  final hasCheckin = entry.value?['checkin_datetime'] != null;

                  return CircleAvatar(
                    radius: radius,
                    backgroundColor:
                        hasCheckin ? Colors.green : Colors.grey.shade400,
                    child: Text(
                      "$controlNum",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: radius * 0.9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChecklistProgressLinePainter extends CustomPainter {
  final int circleCount;
  final double radius;
  final double width;
  final int completedCount;
  final Color completedColor;
  final Color remainingColor;

  _ChecklistProgressLinePainter({
    required this.circleCount,
    required this.radius,
    required this.width,
    required this.completedCount,
    required this.completedColor,
    required this.remainingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (circleCount < 2) return;

    final y = size.height / 2;
    final gap = width / circleCount;
    final firstCenterX = gap / 2;
    final lastCenterX = width - gap / 2;

    final paint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Draw completed portion if any
    if (completedCount > 0) {
      paint.color = completedColor;
      final endX = gap * (completedCount - 1) + gap / 2;
      canvas.drawLine(Offset(firstCenterX, y), Offset(endX, y), paint);
    }

    // Draw remaining portion if not all completed
    if (completedCount < circleCount) {
      paint.color = remainingColor;

      // startX should be the end of the completed portion, or first circle if none completed
      final startX = completedCount > 0
          ? gap * (completedCount - 1) + gap / 2
          : firstCenterX;

      canvas.drawLine(Offset(startX, y), Offset(lastCenterX, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
