import 'package:chessground/chessground.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:zugclient/zug_utils.dart';

enum MoleServMsg {announce,top,history,info,users,moveUpdate,ready,side,confirmMove,voteList,moleBomb,veto,move,rampage,defection,role,startGame,result,version,finger,pgn}
enum MoleClientMsg {pushToken,notify,top,history,cmd,role,status,veto,draw,resign,kickoff,voteoff,move,abort,inspect,bomb,version,finger,pgn}
enum PlayerAction {accuse,kick,ban,finger,whisper,cancel}
enum GamePhase {pregame,voting,veto,postgame}

const kDebugMode = true;
const noGameTitle = "";
const initialFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
enum SideToMove { white, black, none }
const Map<int,PlayerColor?> colorMap = { -1 : null, 0 : PlayerColor.black, 1 : PlayerColor.white };
enum NotificationType { ready, create, start, login }
late final String? pushToken;

const bool defaultStreamerMode = false;
const bool defaultMoveListHover = false;
const int defaultPieceSetIndex = 15;
const String defaultBoardColorScheme = "blueish_gray";

class MoleFields {
  static final IMap<PieceKind,AssetImage> moleSet = Map<PieceKind,AssetImage>.unmodifiable({
    PieceKind.whitePawn: ZugUtils.getAssetImage("images/mole_pieces/mole_pawn_white.png"),
    PieceKind.blackPawn: ZugUtils.getAssetImage("images/mole_pieces/mole_pawn_black.png"),
    PieceKind.whiteKnight: ZugUtils.getAssetImage("images/mole_pieces/mole_knight_white.png"),
    PieceKind.blackKnight: ZugUtils.getAssetImage("images/mole_pieces/mole_knight_black.png"),
    PieceKind.whiteBishop: ZugUtils.getAssetImage("images/mole_pieces/mole_bishop_white.png"),
    PieceKind.blackBishop: ZugUtils.getAssetImage("images/mole_pieces/mole_bishop_black.png"),
    PieceKind.whiteRook: ZugUtils.getAssetImage("images/mole_pieces/mole_rook_white.png"),
    PieceKind.blackRook: ZugUtils.getAssetImage("images/mole_pieces/mole_rook_black.png"),
    PieceKind.whiteQueen: ZugUtils.getAssetImage("images/mole_pieces/mole_queen_white.png"),
    PieceKind.blackQueen: ZugUtils.getAssetImage("images/mole_pieces/mole_queen_black.png"),
    PieceKind.whiteKing: ZugUtils.getAssetImage("images/mole_pieces/mole_king_white.png"),
    PieceKind.blackKing: ZugUtils.getAssetImage("images/mole_pieces/mole_king_black.png"),
  }).toIMap();

  static Map<String,bool> notifications = {
    NotificationType.ready.name : true,
    NotificationType.create.name : true,
    NotificationType.start.name: false,
    NotificationType.login.name : false,
  };

  static const String
      moleFieldPlayer = "player",
      moleFieldMove = "move",
      moleFieldTime = "time",
      moleFieldPromotion = "promotion",
      moleFieldConfirm = "confirm",
      moleFieldSide = "game_col";
}


