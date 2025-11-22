import 'dart:math';
import 'dart:ui' as ui;
import 'package:chessground/chessground.dart' as cg;
import 'package:flutter/cupertino.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_area.dart';
import 'package:zugclient/zug_user.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'mole_fields.dart';

class MoveVote {
  int animationTime = 1000;
  cg.Move move;
  bool player;
  MoveVote(String moveStr, this.player) : move = cg.Move(from: moveStr.substring(0,2), to: moveStr.substring(2,4));
  String get moveString => "${move.from}${move.to}";
}

enum MoleGameStatus {pregame,playing,finished}

enum MolePhase {
  pregame(MoleGameStatus.pregame),
  voting(MoleGameStatus.playing),
  veto(MoleGameStatus.playing),
  postgame(MoleGameStatus.finished);
  final MoleGameStatus status;
  const MolePhase(this.status);
}

enum MoleGameState { pregame, playing, win, lose, draw, finished; }
enum GameResult { win, loss, draw }

class MoleGame extends Area {
  Function(MoleGame) onNewPhase;
  String fen = initialFen;
  List<dynamic> moves = [];
  List<dynamic> chat = [];
  PlayerColor? orientation;
  List<MoveVote> recentVotes = [];
  MoleGameState gameState = MoleGameState.pregame;
  PlayerColor? winCol;
  ui.Image? boardImg;

  MoleGameStatus? get status => phase is MolePhase ? (phase as MolePhase).status : null;

  GameResult? get result => switch(gameState) {
    MoleGameState.pregame || MoleGameState.playing || MoleGameState.finished => null,
    MoleGameState.win => GameResult.win,
    MoleGameState.lose => GameResult.loss,
    MoleGameState.draw => GameResult.draw,
  };

  String get winnerString => switch(winCol) {
    null => "Nobody",
    PlayerColor.black => "Black",
    PlayerColor.white => "White",
  };

  AssetImage get moleImg => switch(winCol) {
    null => ZugUtils.getAssetImage("images/mole_sprite_transparent.gif"),
    PlayerColor.black =>  ZugUtils.getAssetImage("images/mole_sprite_black.gif"),
    PlayerColor.white => ZugUtils.getAssetImage("images/mole_sprite_white.gif"),
  };

  MoleGame(super.data, {required this.onNewPhase});

  void setResult(dynamic data) {
    winCol = colorMap[data[MoleFields.winner]];
    String result = data[MoleFields.result];
    if (result == "win") gameState = MoleGameState.win;
    if (result == "lose") gameState = MoleGameState.lose;
    if (result == "draw") gameState = MoleGameState.draw;
  }

  String getResultString() {
    return switch(gameState) {
      MoleGameState.pregame => "Starting",
      MoleGameState.playing => "Playing",
      MoleGameState.win || MoleGameState.lose => "${cap(winCol?.name ?? "Nobody")} Wins",
      MoleGameState.draw => "Draw",
      MoleGameState.finished => "${cap(winCol?.name ?? "Nobody")} Won",
    };
  }

  String cap(String str) => "${str.substring(0,1).toUpperCase()}${str.length > 1 ? str.substring(1) : ''}";

  SideToMove sideToMove() {
    return fen.split(" ")[1] == "w" ? SideToMove.white : SideToMove.black;
  }

  PlayerColor? getUserSide(UniqueName? userName) {
    if (userName == null) return null;
    dynamic player = getOccupant(userName);
    if (player == null) return null;
    return colorMap[player[MoleFields.side]];
  }

  String getPhaseString() {
    if (phase == ZugPhase.undefined) return " (?) ";
    if (phase == MolePhase.pregame) return " (open) ";
    if (phase == MolePhase.postgame) return " (closing) ";
    return " (running) ";
  }

  String getGameTrack() {
    int i = Random().nextInt(4) + 1;
    return switch(gameState) {
      MoleGameState.pregame => "clue", //TODO: specialized tracks
      MoleGameState.playing => "lobby",
      MoleGameState.win => "victory${i.toString()}",
      MoleGameState.lose => "defeat",
      MoleGameState.draw => "credits",
      MoleGameState.finished => "rap",
    };
  }

  @override
  int compareTo(Area other) {
    if (other is MoleGame) { //print(a.jsonData);
      Iterable<dynamic> players1 = occupantMap.values;
      int p1 = players1.length >= 6 ? 0 : players1.length;
      Iterable<dynamic> players2 = other.occupantMap.values;
      int p2 = players2.length >= 6 ? 0 : players2.length;
      int c = -(p1.compareTo(p2));
      if (c == 0) {
        return super.compareTo(other);
      } else {
        return c;
      }
    }
    return 0;
  }

  @override
  void setPhase(String p) { //print("$id: Setting Phase from $phase to $p");
    final prevPhase = phase.name;
    super.setPhase(p);
    if (phase.name != prevPhase) onNewPhase(this);
  }

  @override
  List<Enum> getPhases() => MolePhase.values;

}