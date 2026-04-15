import 'package:flutter/material.dart';

class PatternLock extends StatefulWidget {
  final ValueChanged<List<int>> onPatternComplete;
  
  const PatternLock({super.key, required this.onPatternComplete});

  @override
  State<PatternLock> createState() => _PatternLockState();
}

class _PatternLockState extends State<PatternLock> {
  List<int> _selectedPoints = [];
  Offset? _currentTouchPoint;

  void _onPanStart(DragStartDetails details) {
    _handleTouch(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _handleTouch(details.localPosition);
    setState(() {
      _currentTouchPoint = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_selectedPoints.isNotEmpty) {
      widget.onPatternComplete(_selectedPoints);
    }
    setState(() {
      _selectedPoints = [];
      _currentTouchPoint = null;
    });
  }

  void _handleTouch(Offset localPosition) {
    // Determine the layout constraints implicitly through 3x3 grid calculation
    const double gridSize = 300.0;
    const double cellSize = gridSize / 3;

    if (localPosition.dx < 0 || localPosition.dx > gridSize ||
        localPosition.dy < 0 || localPosition.dy > gridSize) {
      return;
    }

    int col = (localPosition.dx / cellSize).floor();
    int row = (localPosition.dy / cellSize).floor();
    int index = row * 3 + col;

    // Check distance to center of the cell to prevent accidental swipes hitting cells
    Offset cellCenter = Offset(col * cellSize + cellSize / 2, row * cellSize + cellSize / 2);
    if ((localPosition - cellCenter).distance < cellSize / 2.5) {
        if (!_selectedPoints.contains(index)) {
          setState(() {
            _selectedPoints.add(index);
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: _PatternPainter(
            selectedPoints: _selectedPoints,
            currentTouchPoint: _currentTouchPoint,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
          size: const Size(300, 300),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<int> selectedPoints;
  final Offset? currentTouchPoint;
  final Color primaryColor;

  _PatternPainter({
    required this.selectedPoints,
    required this.currentTouchPoint,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / 3;
    final Paint linePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final Paint dotPaint = Paint()..color = Colors.grey.withValues(alpha: 0.5);
    final Paint selectedDotPaint = Paint()..color = primaryColor;

    // Draw lines
    if (selectedPoints.isNotEmpty) {
      for (int i = 0; i < selectedPoints.length - 1; i++) {
        Offset start = _getCenter(selectedPoints[i], cellSize);
        Offset end = _getCenter(selectedPoints[i + 1], cellSize);
        canvas.drawLine(start, end, linePaint);
      }
      if (currentTouchPoint != null) {
        Offset start = _getCenter(selectedPoints.last, cellSize);
        canvas.drawLine(start, currentTouchPoint!, linePaint);
      }
    }

    // Draw dots
    for (int i = 0; i < 9; i++) {
      Offset center = _getCenter(i, cellSize);
      if (selectedPoints.contains(i)) {
        canvas.drawCircle(center, 12, selectedDotPaint);
      } else {
        canvas.drawCircle(center, 8, dotPaint);
      }
    }
  }

  Offset _getCenter(int index, double cellSize) {
    int row = index ~/ 3;
    int col = index % 3;
    return Offset(col * cellSize + cellSize / 2, row * cellSize + cellSize / 2);
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return true; // Simple approach
  }
}
