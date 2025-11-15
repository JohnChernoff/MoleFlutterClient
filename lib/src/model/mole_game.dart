import 'package:chess/chess.dart' as dc;
import 'package:zugclient/zug_area.dart';
import 'package:zugclient/zug_user.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'mole_fields.dart';

class MoleVote {
  bool confirmed = false;
  int animationTime = 1000;
  dc.Move move;
  int? timestamp;
  MoleVote(this.move);
  bool recent() {
    return confirmed && timestamp != null &&
      (DateTime.now().millisecondsSinceEpoch - timestamp!) < animationTime;
  }
  void confirm({int? millis}) {
    if (millis != null) animationTime = millis;
    confirmed = true;
    timestamp = DateTime.now().millisecondsSinceEpoch;
  }
  String get moveString => "${move.fromAlgebraic}${move.toAlgebraic}";
}

class MoleGame extends Area {

  String fen = initialFen;
  List<dynamic> moves = [];
  List<dynamic> chat = [];
  PlayerColor? orientation;
  MoleVote? lastVote;

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