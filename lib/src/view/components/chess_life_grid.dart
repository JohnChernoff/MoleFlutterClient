import 'dart:math';

/// Represents the state of a single grid square
class GridSquareState {
  bool isAlive;
  int age;
  int attackCount;

  GridSquareState({
    required this.isAlive,
    this.age = 0,
    this.attackCount = 0,
  });

  GridSquareState copyWith({
    bool? isAlive,
    int? age,
    int? attackCount,
  }) {
    return GridSquareState(
      isAlive: isAlive ?? this.isAlive,
      age: age ?? this.age,
      attackCount: attackCount ?? this.attackCount,
    );
  }
}

/// Rules for chess attack-based evolution
class ChessAttackRules {
  final int minSurvivalAttacks;
  final int maxSurvivalAttacks;
  final int minBirthAttacks;
  final int maxBirthAttacks;

  const ChessAttackRules({
    this.minSurvivalAttacks = 0,
    this.maxSurvivalAttacks = 2,
    this.minBirthAttacks = 1,
    this.maxBirthAttacks = 2,
  });

  bool survives(int attackCount) {
    return attackCount >= minSurvivalAttacks &&
        attackCount <= maxSurvivalAttacks;
  }

  bool canBeBorn(int attackCount) {
    return attackCount >= minBirthAttacks && attackCount <= maxBirthAttacks;
  }
}

/// FEN Parser utilities
class FENParser {
  static Map<int, String> parseFEN(String fen) {
    final Map<int, String> pieces = {};
    final boardPart = fen.split(' ')[0];
    final rows = boardPart.split('/');

    int squareIndex = 56;

    for (final row in rows) {
      int fileIndex = 0;

      for (final char in row.split('')) {
        if (char.isEmpty) continue;

        if (RegExp(r'[pnbrqkPNBRQK]').hasMatch(char)) {
          pieces[squareIndex + fileIndex] = char;
          fileIndex++;
        } else if (RegExp(r'\d').hasMatch(char)) {
          fileIndex += int.parse(char);
        }
      }

      squareIndex -= 8;
    }

    return pieces;
  }

  static bool canPieceAttack(
      String piece,
      int fromIndex,
      int toIndex,
      int gridSize,
      ) {
    final fromRank = fromIndex ~/ gridSize;
    final fromFile = fromIndex % gridSize;
    final toRank = toIndex ~/ gridSize;
    final toFile = toIndex % gridSize;

    final rankDiff = (toRank - fromRank).abs();
    final fileDiff = (toFile - fromFile).abs();

    final pieceLower = piece.toLowerCase();

    switch (pieceLower) {
      case 'p':
        final isWhite = piece == piece.toUpperCase();
        if (rankDiff != 1 || fileDiff != 1) return false;
        if (isWhite) return toRank > fromRank;
        return toRank < fromRank;

      case 'n':
        return (rankDiff == 2 && fileDiff == 1) ||
            (rankDiff == 1 && fileDiff == 2);

      case 'b':
        return rankDiff == fileDiff && rankDiff > 0;

      case 'r':
        return (rankDiff == 0 && fileDiff > 0) ||
            (rankDiff > 0 && fileDiff == 0);

      case 'q':
        return (rankDiff == 0 && fileDiff > 0) ||
            (rankDiff > 0 && fileDiff == 0) ||
            (rankDiff == fileDiff && rankDiff > 0);

      case 'k':
        return rankDiff <= 1 && fileDiff <= 1 && (rankDiff > 0 || fileDiff > 0);

      default:
        return false;
    }
  }

  static bool isPathClear(
      int fromIndex,
      int toIndex,
      Map<int, String> pieces,
      int gridSize,
      ) {
    final fromRank = fromIndex ~/ gridSize;
    final fromFile = fromIndex % gridSize;
    final toRank = toIndex ~/ gridSize;
    final toFile = toIndex % gridSize;

    final rankDir = toRank > fromRank ? 1 : (toRank < fromRank ? -1 : 0);
    final fileDir = toFile > fromFile ? 1 : (toFile < fromFile ? -1 : 0);

    var currentRank = fromRank + rankDir;
    var currentFile = fromFile + fileDir;

    while (currentRank != toRank || currentFile != toFile) {
      final index = currentRank * gridSize + currentFile;
      if (pieces.containsKey(index)) return false;
      currentRank += rankDir;
      currentFile += fileDir;
    }

    return true;
  }
}

/// Generic grid-based attack Game of Life (configurable size)
class AttackGameOfLifeGrid {
  final List<List<GridSquareState>> grid;
  final Map<int, String> pieces;
  final int gridSize;
  final double mutationRate;
  final ChessAttackRules rules;
  int generation = 0;

  AttackGameOfLifeGrid({
    required this.grid,
    required this.pieces,
    required this.gridSize,
    required this.mutationRate,
    required this.rules,
  });

  /// Create from FEN and grid size
  factory AttackGameOfLifeGrid.fromFEN(
      String fen,
      int gridSize,
      double mutationRate,
      ChessAttackRules rules,
      ) {
    // Parse FEN as 8x8 board first
    final piecesIn8x8 = FENParser.parseFEN(fen);

    // Create NxN grid
    final grid = List<List<GridSquareState>>.generate(
      gridSize,
          (rank) => List<GridSquareState>.generate(
        gridSize,
            (file) => GridSquareState(isAlive: false),
      ),
    );

    // Center the pieces
    final pieces = <int, String>{};

    if (gridSize == 8) {
      // For 8x8, use pieces as-is
      pieces.addAll(piecesIn8x8);
      for (final entry in piecesIn8x8.entries) {
        final rank = entry.key ~/ 8;
        final file = entry.key % 8;
        grid[rank][file] = GridSquareState(isAlive: true);
      }
    } else {
      // Center the 8x8 board within the larger grid
      final offset = (gridSize - 8) ~/ 2;

      for (final entry in piecesIn8x8.entries) {
        final rank8x8 = entry.key ~/ 8;
        final file8x8 = entry.key % 8;

        final centeredRank = rank8x8 + offset;
        final centeredFile = file8x8 + offset;
        final centeredIndex = centeredRank * gridSize + centeredFile;

        pieces[centeredIndex] = entry.value;
        grid[centeredRank][centeredFile] = GridSquareState(isAlive: true);
      }
    }

    return AttackGameOfLifeGrid(
      grid: grid,
      pieces: pieces,
      gridSize: gridSize,
      mutationRate: mutationRate,
      rules: rules,
    );
  }

  /// Count how many pieces are attacking a given square
  int countAttackers(int squareIndex) {
    int count = 0;

    for (final entry in pieces.entries) {
      final fromIndex = entry.key;
      final piece = entry.value;

      if (FENParser.canPieceAttack(piece, fromIndex, squareIndex, gridSize)) {
        final pieceLower = piece.toLowerCase();
        if (['b', 'r', 'q'].contains(pieceLower)) {
          if (FENParser.isPathClear(fromIndex, squareIndex, pieces, gridSize)) {
            count++;
          }
        } else {
          count++;
        }
      }
    }

    return count;
  }

  /// Get the piece type that should be born at a square
  String? getBornPieceType(int squareIndex) {
    if (Random().nextDouble() < mutationRate) {
      const pieceTypes = ['p', 'n', 'b', 'r', 'q', 'k'];
      return pieceTypes[Random().nextInt(pieceTypes.length)];
    }

    final attackingPieces = <String>[];

    for (final entry in pieces.entries) {
      final fromIndex = entry.key;
      final piece = entry.value;

      if (FENParser.canPieceAttack(piece, fromIndex, squareIndex, gridSize)) {
        final pieceLower = piece.toLowerCase();
        if (['b', 'r', 'q'].contains(pieceLower)) {
          if (FENParser.isPathClear(fromIndex, squareIndex, pieces, gridSize)) {
            attackingPieces.add(pieceLower);
          }
        } else {
          attackingPieces.add(pieceLower);
        }
      }
    }

    if (attackingPieces.isEmpty) return null;

    final pieceCounts = <String, int>{};
    for (final piece in attackingPieces) {
      pieceCounts[piece] = (pieceCounts[piece] ?? 0) + 1;
    }

    return pieceCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Evolve grid one generation
  AttackGameOfLifeGrid step() {
    final newGrid = List<List<GridSquareState>>.generate(
      gridSize,
          (rank) => List<GridSquareState>.generate(
        gridSize,
            (file) {
          final squareIndex = rank * gridSize + file;
          final currentCell = grid[rank][file];
          final attackCount = countAttackers(squareIndex);

          if (currentCell.isAlive) {
            if (rules.survives(attackCount)) {
              return currentCell.copyWith(
                isAlive: true,
                age: currentCell.age + 1,
                attackCount: attackCount,
              );
            } else {
              return currentCell.copyWith(
                isAlive: false,
                age: 0,
                attackCount: attackCount,
              );
            }
          } else {
            if (rules.canBeBorn(attackCount)) {
              return currentCell.copyWith(
                isAlive: true,
                age: 0,
                attackCount: attackCount,
              );
            } else {
              return currentCell.copyWith(attackCount: attackCount);
            }
          }
        },
      ),
    );

    final newPieces = <int, String>{};
    for (int rank = 0; rank < gridSize; rank++) {
      for (int file = 0; file < gridSize; file++) {
        final squareIndex = rank * gridSize + file;
        if (newGrid[rank][file].isAlive) {
          if (pieces.containsKey(squareIndex)) {
            newPieces[squareIndex] = pieces[squareIndex]!;
          } else {
            final bornType = getBornPieceType(squareIndex);
            if (bornType != null) {
              bool isWhite = false;
              for (final entry in pieces.entries) {
                if (entry.key != squareIndex) {
                  final piece = entry.value;
                  if (FENParser.canPieceAttack(
                      piece, entry.key, squareIndex, gridSize)) {
                    isWhite = piece == piece.toUpperCase();
                    break;
                  }
                }
              }
              newPieces[squareIndex] =
              isWhite ? bornType.toUpperCase() : bornType;
            }
          }
        }
      }
    }

    final newGridObj = AttackGameOfLifeGrid(
      grid: newGrid,
      pieces: newPieces,
      gridSize: gridSize,
      mutationRate: mutationRate,
      rules: rules,
    );
    newGridObj.generation = generation + 1;
    return newGridObj;
  }
}
