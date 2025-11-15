import 'package:chessground/chessground.dart' as cg;
import 'package:chess/chess.dart' as dc;
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

class MoleGame extends Area {

  String fen = initialFen;
  List<dynamic> moves = [];
  List<dynamic> chat = [];
  PlayerColor? orientation;
  List<MoveVote> recentVotes = [];

  MoleGame(super.data);

  SideToMove sideToMove() {
    return fen.split(" ")[1] == "w" ? SideToMove.white : SideToMove.black;
  }

  PlayerColor? getUserSide(UniqueName? userName) {
    if (userName == null) return null;
    dynamic player = getOccupant(userName);
    if (player == null) return null;
    return colorMap[player[MoleFields.moleFieldSide]];
  }

  String getPhaseString() {
    if (phase == ZugPhase.undefined) return " (?) ";
    if (phase == MolePhase.pregame) return " (open) ";
    if (phase == MolePhase.postgame) return " (closing) ";
    return " (running) ";
  }

  @override
  List<Enum> getPhases() => MolePhase.values;

}