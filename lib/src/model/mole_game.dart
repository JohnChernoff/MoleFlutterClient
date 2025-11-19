import 'dart:math';
import 'dart:ui' as ui;
import 'package:chessground/chessground.dart' as cg;
import 'package:flutter/cupertino.dart';
import 'package:mole_app/src/view/components/result_animation.dart';
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

class MoleGame extends Area {

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

  MoleGame(super.data);

  void setResult(dynamic data) {
    winCol = colorMap[data[MoleFields.winner]];
    String result = data[MoleFields.result];
    if (result == "win") gameState = MoleGameState.win;
    if (result == "lose") gameState = MoleGameState.lose;
    if (result == "draw") gameState = MoleGameState.draw;
  }

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
      MoleGameState.pregame => "mole_intro2",
      MoleGameState.playing => "mole_intro2",
      MoleGameState.win => "mole_victory${i.toString()}",
      MoleGameState.lose => "mole_defeat",
      MoleGameState.draw => "mole_intro2",
      MoleGameState.finished => "mole_intro2",
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
  List<Enum> getPhases() => MolePhase.values;

}