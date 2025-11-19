import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

/// Color state in the Game of Life
/// Each color represents a different state with unique birth/survival rules
class CellState {
  final Color color;
  final int age; // How many generations this cell has existed

  CellState(this.color, [this.age = 0]);

  CellState evolve() => CellState(color, age + 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CellState &&
              runtimeType == other.runtimeType &&
              color == other.color;

  @override
  int get hashCode => color.hashCode;
}

/// Rules for colored Game of Life
/// Maps neighbor counts to birth/survival conditions per color
class ColorLifeRules {
  // Birth conditions: { neighborColor: { count: shouldBeBorn } }
  final Map<int, Set<int>> birthRules;
  // Survival conditions: { neighborColor: { count: shouldSurvive } }
  final Map<int, Set<int>> survivalRules;

  ColorLifeRules({
    Map<int, Set<int>>? birthRules,
    Map<int, Set<int>>? survivalRules,
  })  : birthRules = birthRules ?? _defaultBirthRules,
        survivalRules = survivalRules ?? _defaultSurvivalRules;

  // Classic Conway: birth on 3, survive on 2-3
  static const Map<int, Set<int>> _defaultBirthRules = {
    // Dead cells (white/0) birth on 3 neighbors
    0: {3},
  };

  static const Map<int, Set<int>> _defaultSurvivalRules = {
    // Live cells survive on 2-3 neighbors
    1: {2, 3},
  };
}

/// Grid for Game of Life simulation
class GameOfLifeGrid {
  final List<List<CellState>> grid;
  final int width;
  final int height;
  final ColorLifeRules rules;

  GameOfLifeGrid({
    required this.width,
    required this.height,
    required this.grid,
    required this.rules,
  });

  factory GameOfLifeGrid.fromImage(
      ui.Image image, {
        ColorLifeRules? rules,
        bool invertColors = false,
      }) {
    final width = image.width;
    final height = image.height;
    final grid = <List<CellState>>[];

    // Convert image to byte data
    image.toByteData().then((byteData) {
      // Implementation happens in the widget
    });

    // For now, create from pixel data
    final newGrid = List<List<CellState>>.generate(
      height,
          (y) => List<CellState>.generate(
        width,
            (x) => CellState(Colors.black),
      ),
    );

    return GameOfLifeGrid(
      width: width,
      height: height,
      grid: newGrid,
      rules: rules ?? ColorLifeRules(),
    );
  }

  factory GameOfLifeGrid.fromImageBytes(
      Uint8List bytes,
      int width,
      int height, {
        ColorLifeRules? rules,
        int pixelationFactor = 1,
      }) {
    // Scale down the image by pixelating it
    int scaledWidth = (width ~/ pixelationFactor).clamp(1, width);
    int scaledHeight = (height ~/ pixelationFactor).clamp(1, height);

    final grid = List<List<CellState>>.generate(
      scaledHeight,
          (y) => List<CellState>.generate(
        scaledWidth,
            (x) {
          // Sample a block of pixels and average them
          final avgColor = _samplePixelBlock(
            bytes,
            x,
            y,
            width,
            height,
            pixelationFactor,
          );

          // Treat pure white (or near-white) as dead, anything else as alive
          final isAlive = !(avgColor.red > 240 &&
              avgColor.green > 240 &&
              avgColor.blue > 240 &&
              avgColor.alpha > 200);

          return CellState(isAlive ? avgColor : Colors.white, 0);
        },
      ),
    );

    return GameOfLifeGrid(
      width: scaledWidth,
      height: scaledHeight,
      grid: grid,
      rules: rules ?? ColorLifeRules(),
    );
  }

  static Color _samplePixelBlock(
      Uint8List bytes,
      int gridX,
      int gridY,
      int originalWidth,
      int originalHeight,
      int factor,
      ) {
    int rSum = 0, gSum = 0, bSum = 0, aSum = 0;
    int pixelCount = 0;

    // Sample the block of pixels
    for (int dy = 0; dy < factor; dy++) {
      for (int dx = 0; dx < factor; dx++) {
        final pixelX = (gridX * factor + dx).clamp(0, originalWidth - 1);
        final pixelY = (gridY * factor + dy).clamp(0, originalHeight - 1);
        final pixelIndex = (pixelY * originalWidth + pixelX) * 4;

        rSum += bytes[pixelIndex];
        gSum += bytes[pixelIndex + 1];
        bSum += bytes[pixelIndex + 2];
        aSum += bytes[pixelIndex + 3];
        pixelCount++;
      }
    }

    // Average the values
    return Color.fromARGB(
      (aSum ~/ pixelCount).clamp(0, 255),
      (rSum ~/ pixelCount).clamp(0, 255),
      (gSum ~/ pixelCount).clamp(0, 255),
      (bSum ~/ pixelCount).clamp(0, 255),
    );
  }

  /// Count neighbors of a specific cell
  int countNeighbors(int x, int y) {
    int count = 0;
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        final nx = (x + dx + width) % width;
        final ny = (y + dy + height) % height;
        if (grid[ny][nx].color != Colors.white) count++;
      }
    }
    return count;
  }

  /// Get dominant color from neighbors
  Color getDominantNeighborColor(int x, int y) {
    final colorCounts = <Color, int>{};
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        if (dx == 0 && dy == 0) continue;
        final nx = (x + dx + width) % width;
        final ny = (y + dy + height) % height;
        final color = grid[ny][nx].color;
        if (color != Colors.white) {
          colorCounts[color] = (colorCounts[color] ?? 0) + 1;
        }
      }
    }

    return colorCounts.isEmpty
        ? Colors.white
        : colorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Evolve grid one generation
  GameOfLifeGrid step() {
    final newGrid = List<List<CellState>>.generate(
      height,
          (y) => List<CellState>.generate(
        width,
            (x) {
          final currentCell = grid[y][x];
          final neighborCount = countNeighbors(x, y);
          final isAlive = currentCell.color != Colors.white;

          bool survives = false;
          if (isAlive && rules.survivalRules[1]?.contains(neighborCount) == true) {
            survives = true;
          }

          if (!survives && neighborCount == 3) {
            // Birth
            final dominantColor = getDominantNeighborColor(x, y);
            return CellState(dominantColor, 0);
          } else if (survives) {
            return currentCell.evolve();
          } else {
            return CellState(Colors.white, 0);
          }
        },
      ),
    );

    return GameOfLifeGrid(
      width: width,
      height: height,
      grid: newGrid,
      rules: rules,
    );
  }

  /// Render grid to image
  Future<ui.Image> render(int cellSize) {
    final pixelWidth = width * cellSize;
    final pixelHeight = height * cellSize;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final cell = grid[y][x];
        final paint = Paint()..color = cell.color;
        canvas.drawRect(
          Rect.fromLTWH(
            x * cellSize.toDouble(),
            y * cellSize.toDouble(),
            cellSize.toDouble(),
            cellSize.toDouble(),
          ),
          paint,
        );
      }
    }

    return recorder.endRecording().toImage(pixelWidth, pixelHeight);
  }
}

/// Main widget for displaying Game of Life animation
class ConwayGameOfLifeWidget extends StatefulWidget {
  final ui.Image image;
  final int cellSize;
  final int pixelationFactor;
  final Duration updateInterval;
  final ColorLifeRules? rules;
  final bool autoPlay;
  final VoidCallback? onGenerationChange;

  const ConwayGameOfLifeWidget({
    required this.image,
    this.cellSize = 2,
    this.pixelationFactor = 1,
    this.updateInterval = const Duration(milliseconds: 100),
    this.rules,
    this.autoPlay = true,
    this.onGenerationChange,
    super.key,
  });

  @override
  State<ConwayGameOfLifeWidget> createState() =>
      _ConwayGameOfLifeWidgetState();
}

class _ConwayGameOfLifeWidgetState extends State<ConwayGameOfLifeWidget> {
  late GameOfLifeGrid currentGrid;
  late Future<void> _initializationFuture;
  int generation = 0;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    isPlaying = widget.autoPlay;
    _initializationFuture = _initializeGrid();
  }

  Future<void> _initializeGrid() async {
    final byteData = await widget.image.toByteData();
    if (byteData != null) {
      currentGrid = GameOfLifeGrid.fromImageBytes(
        byteData.buffer.asUint8List(),
        widget.image.width,
        widget.image.height,
        rules: widget.rules,
        pixelationFactor: widget.pixelationFactor,
      );
      if (mounted && isPlaying) {
        _startAnimation();
      }
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
      generation++;
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

  void reset() async {
    await _initializeGrid();
    setState(() {
      generation = 0;
      if (isPlaying) {
        _startAnimation();
      }
    });
  }

  void stepOnce() {
    setState(() {
      currentGrid = currentGrid.step();
      generation++;
      widget.onGenerationChange?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Expanded(
              child: Center(
                child: CustomPaint(
                  painter: GameOfLifePainter(
                    grid: currentGrid,
                    cellSize: widget.cellSize,
                  ),
                  size: Size(
                    currentGrid.width * widget.cellSize.toDouble(),
                    currentGrid.height * widget.cellSize.toDouble(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Generation: $generation',
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
      },
    );
  }
}

/// Custom painter for rendering the game grid
class GameOfLifePainter extends CustomPainter {
  final GameOfLifeGrid grid;
  final int cellSize;

  GameOfLifePainter({
    required this.grid,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int y = 0; y < grid.height; y++) {
      for (int x = 0; x < grid.width; x++) {
        final cell = grid.grid[y][x];
        final paint = Paint()
          ..color = cell.color
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(
            x * cellSize.toDouble(),
            y * cellSize.toDouble(),
            cellSize.toDouble(),
            cellSize.toDouble(),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(GameOfLifePainter oldDelegate) =>
      oldDelegate.grid != grid;
}
