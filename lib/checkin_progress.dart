import 'package:flutter/material.dart';
import 'checkin.dart';

class CheckinProgress extends StatelessWidget {
  final List<Checkin?> checklist;
  final int numControls;

  const CheckinProgress(
      {super.key, required this.checklist, required this.numControls});

  @override
  Widget build(BuildContext context) {
    if (numControls <= 0) {
      return const Text("No controls");
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // final count = checklist!
        // .length;
        final maxWidth = constraints.maxWidth;
        final circleDiameter = (maxWidth / numControls) - 6;
        final radius = (circleDiameter / 2).clamp(8.0, 15.0);

        final completed = List<bool>.generate(
          numControls,
          (i) => i < checklist.length && checklist[i] != null,
        );

        return SizedBox(
          height: radius * 2,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ChecklistProgressLinePainter(
                    circleCount: numControls,
                    radius: radius,
                    width: maxWidth,
                    completed: completed,
                    completedColor: Colors.green,
                    remainingColor: Colors.grey.shade400,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < numControls; i++)
                    CircleAvatar(
                      radius: radius,
                      backgroundColor:
                          i < checklist.length && checklist[i] != null
                              ? Colors.green
                              : Colors.grey.shade400,
                      child: Text(
                        "${i + 1}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: radius * 0.9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                ],
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
  final List<bool> completed;
  final Color completedColor;
  final Color remainingColor;

  _ChecklistProgressLinePainter({
    required this.circleCount,
    required this.radius,
    required this.width,
    required this.completed,
    required this.completedColor,
    required this.remainingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (circleCount < 2) return;

    final y = size.height / 2;
    final gap = width / circleCount;

    final paint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < circleCount - 1; i++) {
      final startX = gap * i + gap / 2;
      final endX = gap * (i + 1) + gap / 2;

      paint.color =
          completed[i] && completed[i + 1] ? completedColor : remainingColor;

      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChecklistProgressLinePainter oldDelegate) {
    return circleCount != oldDelegate.circleCount ||
        radius != oldDelegate.radius ||
        width != oldDelegate.width ||
        completed != oldDelegate.completed ||
        completedColor != oldDelegate.completedColor ||
        remainingColor != oldDelegate.remainingColor;
  }
}
