import 'package:flutter/material.dart';
import 'package:mole_app/src/view/components/chess_life_grid.dart';

/// Main widget for attack-based Game of Life (configurable grid size)
class AttackGameOfLifeWidget extends StatefulWidget {
  final String initialFEN;
  final int gridSize; // NxN grid (e.g., 8 for 8x8, 255 for 255x255)
  final Duration updateInterval;
  final bool autoPlay;
  final double boardDisplaySize;
  final double mutationRate;
  final ChessAttackRules rules;
  final VoidCallback? onGenerationChange;

  const AttackGameOfLifeWidget({
    required this.initialFEN,
    this.gridSize = 8,
    this.updateInterval = const Duration(milliseconds: 300),
    this.autoPlay = true,
    this.boardDisplaySize = 480,
    this.mutationRate = 0.0,
    this.rules = const ChessAttackRules(),
    this.onGenerationChange,
    super.key,
  });

  @override
  State<AttackGameOfLifeWidget> createState() =>
      _ChessAttackGameOfLifeWidgetState();
}

class _ChessAttackGameOfLifeWidgetState
    extends State<AttackGameOfLifeWidget> {
  late AttackGameOfLifeGrid currentGrid;
  bool isPlaying = false;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    isPlaying = widget.autoPlay;
    _initializeGrid();
  }

  void _initializeGrid() {
    try {
      currentGrid = AttackGameOfLifeGrid.fromFEN(
        widget.initialFEN,
        widget.gridSize,
        widget.mutationRate,
        widget.rules,
      );
      setState(() {
        isInitialized = true;
      });
      if (isPlaying) {
        _startAnimation();
      }
    } catch (e) {
      print('Error initializing grid: $e');
    }
  }

  void _startAnimation() {
    Future.delayed(widget.updateInterval, () {
      if (mounted && isPlaying) {
        _step();
      }
    });
  }

  void _step() {
    setState(() {
      currentGrid = currentGrid.step();
      widget.onGenerationChange?.call();
    });
    _startAnimation();
  }

  void togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });
    if (isPlaying) {
      _startAnimation();
    }
  }

  void reset() {
    _initializeGrid();
  }

  void stepOnce() {
    setState(() {
      currentGrid = currentGrid.step();
      widget.onGenerationChange?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: CustomPaint(
              painter: AttackGameOfLifePainter(
                grid: currentGrid,
                boardDisplaySize: widget.boardDisplaySize,
              ),
              size: Size(widget.boardDisplaySize, widget.boardDisplaySize),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Generation: ${currentGrid.generation}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: reset,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset',
                  ),
                  IconButton(
                    onPressed: stepOnce,
                    icon: const Icon(Icons.skip_next),
                    tooltip: 'Step once',
                  ),
                  IconButton(
                    onPressed: togglePlayPause,
                    icon: Icon(isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle),
                    tooltip: isPlaying ? 'Pause' : 'Play',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter - draws a procedural board with pieces
class AttackGameOfLifePainter extends CustomPainter {
  final AttackGameOfLifeGrid grid;
  final double boardDisplaySize;

  AttackGameOfLifePainter({
    required this.grid,
    required this.boardDisplaySize,
  });

  static const Map<String, String> pieceSymbols = {
    'p': '♟',
    'n': '♞',
    'b': '♝',
    'r': '♜',
    'q': '♛',
    'k': '♚',
    'P': '♙',
    'N': '♘',
    'B': '♗',
    'R': '♖',
    'Q': '♕',
    'K': '♔',
  };

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = boardDisplaySize / grid.gridSize;

    for (int rank = 0; rank < grid.gridSize; rank++) {
      for (int file = 0; file < grid.gridSize; file++) {
        final squareIndex = rank * grid.gridSize + file;
        final squareState = grid.grid[rank][file];
        final x = file * squareSize;
        final y = rank * squareSize;

        // Draw checkerboard pattern
        final isLightSquare = (rank + file) % 2 == 0;
        final squarePaint = Paint()
          ..color = isLightSquare
              ? const Color(0xFFF0D9B5)
              : const Color(0xFFB58863);

        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          squarePaint,
        );

        // Draw attack count indicator (subtle background)
        if (squareState.attackCount > 0) {
          Color indicatorColor;
          double opacity;

          if (squareState.attackCount == 1) {
            indicatorColor = const Color(0xFF2196F3); // Blue
            opacity = 0.15;
          } else if (squareState.attackCount == 2) {
            indicatorColor = const Color(0xFFFFEB3B); // Yellow
            opacity = 0.15;
          } else {
            indicatorColor = const Color(0xFFF44336); // Red
            opacity = 0.2;
          }

          final indicatorPaint = Paint()
            ..color = indicatorColor.withOpacity(opacity);

          canvas.drawRect(
            Rect.fromLTWH(x, y, squareSize, squareSize),
            indicatorPaint,
          );
        }

        // Draw piece if alive
        if (squareState.isAlive && grid.pieces.containsKey(squareIndex)) {
          final piece = grid.pieces[squareIndex]!;
          final symbol = pieceSymbols[piece] ?? '?';
          final isWhite = piece == piece.toUpperCase();

          final textPainter = TextPainter(
            text: TextSpan(
              text: symbol,
              style: TextStyle(
                fontSize: squareSize * 0.75,
                fontWeight: FontWeight.bold,
                color: isWhite ? Colors.white : Colors.black,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    color: isWhite ? Colors.black87 : Colors.white70,
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          );

          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              x + (squareSize - textPainter.width) / 2,
              y + (squareSize - textPainter.height) / 2,
            ),
          );
        }

        // Draw border based on state
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        if (squareState.isAlive) {
          borderPaint.color = const Color(0xFF76FF03).withOpacity(0.5); // Green Accent
        } else {
          borderPaint.color = Colors.grey.withOpacity(0.2);
        }

        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          borderPaint,
        );

        // Draw attack count text in corner
        if (squareState.attackCount > 0) {
          final countText = TextPainter(
            text: TextSpan(
              text: squareState.attackCount.toString(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          countText.layout();
          countText.paint(canvas, Offset(x + 2, y + 2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(AttackGameOfLifePainter oldDelegate) =>
      oldDelegate.grid != grid;
}
