import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:chess/chess.dart' as dc;
import 'package:chessground/chessground.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:mole_app/src/mole_dialogs.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zug_utils/zug_dialogs.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/dialogs.dart';
import 'package:zugclient/zug_area.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_model.dart';
import 'package:zugclient/zug_option.dart';
import 'package:zugclient/zug_user.dart';
import '../firebase_options.dart';
import 'package:flutter/services.dart';
import 'mole_fields.dart';

//TODO: ZugOptions, Lobby dimensions

class MoleGame extends Area {

  String fen = initialFen;
  List<dynamic> moves = [];
  List<dynamic> chat = [];
  PlayerColor? orientation;

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

class CustomPieceSet {
  String name;
  IMap<PieceKind, AssetImage> pieceSet;
  CustomPieceSet(this.name,this.pieceSet);
}

enum MoleOption {pieceSet,boardColors,streamerMode}
enum MoleClip {accuse,defect,rampage,bomb,create,doink,moveBlack,moveWhite,vote,roleInspector,roleMole,rolePlayer}

class MoleClient extends ZugModel {

  dc.Chess chess = dc.Chess();
  Map<Enum,Completer> waitMap = {};
  int lastUpdate = 0;
  bool starting = true;
  Map<String, dynamic> options = {};
  bool modal = false;
  List<dynamic> lobbyLog = [];
  List<dynamic> topPlayers = [];
  Map<String,dynamic> playerHistory = {};
  bool confirmAI = false;
  List<CustomPieceSet> customSets = [];
  ChessBoardController chessBoardController = ChessBoardController();
  Map<String,AssetSource> clips = {};

  MoleClient(super.domain, super.port, super.remoteEndpoint, super.prefs, {super.javalinServer, super.localServer}) {
    modelName = "mole_client";
    areaName = "Mole Game";
    addFunctions({
      ServMsg.ip : handleIP,
      MoleServMsg.move : handleMove,
      MoleServMsg.role : handleRole,
      MoleServMsg.defection : handleDefection,
      MoleServMsg.rampage : handleRampage,
      MoleServMsg.moleBomb : handleMolebomb,
      MoleServMsg.voteList : handleVotelist,
      MoleServMsg.top : handleTop,
      MoleServMsg.history : handlePlayerHistory,
      MoleServMsg.result : handleResult,
      MoleServMsg.finger : handleFinger,
      MoleServMsg.pgn : handlePGN,
      MoleServMsg.announce : handleAlertMsg,
    });
    for (var key in getFunctions().keys) {
      waitMap.putIfAbsent(key, () => Completer());
    }
    loadChessgroundPieceSets();
    loadOptions([
      (MoleOption.pieceSet,ZugOption(customSets.last.name,label: "Piece Set", enums: List.generate(customSets.length, (i) => customSets.elementAt(i).name))),
      (MoleOption.boardColors,ZugOption(BoardColor.green.name,label: "Board Color",enums: List.generate(BoardColor.values.length, (i) => BoardColor.values.elementAt(i).name))),
      (MoleOption.streamerMode,ZugOption(false,label: "Streamer Mode"))
    ]);

    for (MoleClip clip in MoleClip.values) { //print("Loading: ${clip.name}");
      clips.putIfAbsent(clip.name, () => AssetSource("audio/clips/${clip.name}.mp3"));
    }

    //print(waitMap[MoleServMsg.history]);
    //initFire().then((value) {  //_connect(); } );
  }

  getGame(dynamic data) => getOrCreateArea(data) as MoleGame;

  void loadChessgroundPieceSets() {
    for (var set in PieceSet.values) {
      customSets.add(CustomPieceSet(set.name, set.assets));
    }
    customSets.add(CustomPieceSet("mole", MoleFields.moleSet));
  }

  @override
  void startArea() {
    ZugDialogs.getValue(const ValueDialog(TimeSelectDialogOptions()))
        .then((value) => areaCmd(ClientMsg.startArea, data: {"time" : value}));
  }

  @override
  Area createArea(dynamic data) {
    return MoleGame(data);
  }

  @override
  Future<bool> loggedIn(data) async {
    if (autoJoinTitle == null) {
      int i = Random().nextInt(2) + 1;
      ZugDialogs.showClickableDialog(MusicStackDialog(this,"mole_intro1",
          [
            Image(image: ZugUtils.getAssetImage("images/mole_dance_bkg${i.toString()}.gif")),
            Image(image: ZugUtils.getAssetImage("images/mole_dance3.gif")),
          ]
      ));
    }
    return super.loggedIn(data);
  }

  @override
  void connected() {
    ZugModel.log.info("Connected");
    super.connected();
    send(MoleClientMsg.version);
    checkRedirect("lichess.org");
  }

  @override
  void handleVersion(data) { //TODO: why?
    super.handleVersion(data);
    ZugUtils.getIP().then((address) => send(ClientMsg.ip,data: {fieldAddress : address}));
    //send(ClientMsg.ip,data: {fieldAddress : Random().nextInt(255).toString()});
  }

  void handleIP(data) {
    ZugModel.log.info("IP Address: ${data[fieldAddress]}");
  }

  MoleGame getCurrentGame() {
    return currentArea as MoleGame;
  }

  void handlePlayerAction(Map<String, dynamic> action) { //print(action);
    if (action[MoleFields.moleFieldAction] == PlayerAction.accuse) {
      ZugDialogs.confirm("Accuse ${action[fieldUniqueName]}?").then((confirmed) {
        if (confirmed) {
          send(MoleClientMsg.voteoff, data: {
            fieldPlayer: action[fieldUniqueName].toJSON(),
            fieldAreaID: action[fieldAreaID]
          });
        }
      });
    }
    else if (action[MoleFields.moleFieldAction] == PlayerAction.kick) {
      ZugDialogs.confirm("Kick ${action[fieldUniqueName]}?").then((confirmed) {
        if (confirmed) {
          send(MoleClientMsg.kickoff, data: {
            fieldPlayer: action[fieldUniqueName].toJSON(),
            fieldAreaID: action[fieldAreaID]
          });
        }
      });
    }
    else if (action[MoleFields.moleFieldAction] == PlayerAction.ban) {
      ZugDialogs.confirm("Ban ${action[fieldUniqueName]}?").then((confirmed) {
        if (confirmed) {
          send(ClientMsg.ban, data: {
            fieldName: action[fieldUniqueName].toJSON(),
            fieldAreaID: action[fieldAreaID]
          });
        }
      });
    }
    else if (action[MoleFields.moleFieldAction] == PlayerAction.finger) {
      send(MoleClientMsg.finger, data: {
        fieldName: action[fieldUniqueName].toJSON(),
      });
    }
    else if (action[MoleFields.moleFieldAction] == PlayerAction.whisper) {
      ZugDialogs.getString("Enter a whisper to ${action[fieldUniqueName]}", "").then((msg) =>
      send(ClientMsg.privMsg, data: {
        fieldName: action[fieldUniqueName].toJSON(),
        fieldMsg: msg
      }));
    }
  }

  void getTop(int n) {
    waitMap[MoleServMsg.top] = Completer();
    send(MoleServMsg.top,data: {"n" : n});
  }

  void handleTop(data) { //print("Top: " + data.toString());
    topPlayers = data;
    if (waitMap[MoleServMsg.top]?.isCompleted != true) {
      waitMap[MoleServMsg.top]?.complete();
    }

  }

  void handleFinger(data) {
    ZugDialogs.popup(data.toString());
  }

  Future<void> handlePGN(data) async {
    Clipboard.setData(ClipboardData(text: data[fieldMsg] ?? "?".toString())).then((value) => ZugDialogs.popup("Copied PGN to clipboard"));
  }

  void getPlayerHistory(UniqueName? uName) {
    waitMap[MoleServMsg.history] = Completer();
    send(MoleClientMsg.history,data: { fieldPlayer : uName?.toJSON() });
  }

  void handlePlayerHistory(data) {
    playerHistory = data;
    if (waitMap[MoleServMsg.history] != null) {
      ZugModel.log.info("Waiting on history");
    }
    waitMap[MoleServMsg.history]?.complete();
  }

  void handleVotelist(data) { //print("Votes: $data");
    Area game = getOrCreateArea(data); //print(game.occupantMap.values.length);
    if (game is MoleGame && game == currentArea) {
      for (dynamic vote in data["votes"]) {
        UniqueName uname = UniqueName.fromData(vote[fieldPlayer][fieldUser]); //print(uname);
        dynamic player = game.getOccupant(uname); //print("Player: $player");
        player["move"] = vote["move"];
      }
    }
  }

  void handleDefection(data) { //print("Defection: $data");
    Area game = getOrCreateArea(data);
    if (game is MoleGame && game == currentArea) {
      playClip(MoleClip.defect.name);
      ZugDialogs.popup("${UniqueName.fromData(data[fieldPlayer][fieldUser])} defects!",
          imgFile: "defection.png");
    }
  }

  void handleRampage(data) { //print("Rampage: $data");
    Area game = getOrCreateArea(data);
    if (game is MoleGame && game == currentArea) {
      playClip(MoleClip.rampage.name);
      ZugDialogs.popup("${UniqueName.fromData(data[fieldPlayer][fieldUser])} rampages!",
          imgFile: "rampage.png");
    }
  }

  void handleMolebomb(data) {
    Area game = getOrCreateArea(data);
    if (game is MoleGame && game == currentArea) {
      playClip(MoleClip.bomb.name);
      ZugDialogs.popup("${UniqueName.fromData(data)} bombs!",
          imgFile: "molebomb.png");
    }
  }

  void playClip(String n) {
    if (clips.containsKey(n)) playAudio(clips[n]!,clip: true);
  }

  void handleResult(data) { //TODO: figure out side better
    Area game = getOrCreateArea(data);
    if (game is MoleGame && game == currentArea) {
      PlayerColor? winner = colorMap[data["result"]];
      String winnerString = switch(winner) {
        null => "Nobody",
        PlayerColor.black => "Black",
        PlayerColor.white => "White",
      };
      Image moleImg = switch(winner) {
        null => Image(image: ZugUtils.getAssetImage("images/mole_sprite_transparent.gif")),
        PlayerColor.black =>  Image(image: ZugUtils.getAssetImage("images/mole_sprite_black.gif")),
        PlayerColor.white => Image(image: ZugUtils.getAssetImage("images/mole_sprite_white.gif")),
      };

      PlayerColor? side = game.getUserSide(userName);
      String track;

      if (winner == null) {
        track = "mole_intro2"; //TODO: draw music
      }
      else if (winner == side) {
        int i = Random().nextInt(4) + 1;
        track = "mole_victory${i.toString()}";
      }
      else {
        track = "mole_defeat";
      }

      ZugDialogs.showClickableDialog(
          MusicStackDialog(this,track,[MoleDance("Game Over: $winnerString Wins!",moleImg)])
      );
    }
  }

  bool isStreamerMode() {
    return prefs?.getBool("streamer_mode") ?? defaultStreamerMode;
  }

  void handleRole(data) {
    String role = data[fieldMsg]; //if (game is MoleGame && game == currentArea) {}
    if (isStreamerMode()) {
      addAreaMsg("You are the $role",data[fieldAreaID],hidden: true);
    }
    else {
      playClip("role_${role.toLowerCase()}");
      ZugDialogs.popup("You are the $role",imgFile: "${role.toLowerCase()}.png");
    }
  }

  @override
  bool handleNewPhase(data) { //print("New Phase: $data");
    if (data["phase"] == "POSTGAME") {
      addAreaMsg(
          "Game closing in ${data["timeRemaining"]} seconds",
          data[fieldAreaID]
      );
    }
    return super.handleNewPhase(data);
  }

  void handleMove(data) { //print("New Move: ${jsonEncode(data).toString()}");
    MoleGame game = getGame(data);
    playClip(game.sideToMove() == SideToMove.black ? "move_black" : "move_white"); //TODO: fix NPE
    if (data["move_votes"] != null) {
      //print("${game.moves.length}: ${data["ply"]}");
      if (game.moves.length + 1 == data["ply"]) {
        game.moves.add(data["move_votes"]);
        //if (kIsWeb) {  Future.delayed(const Duration(milliseconds: 250)).then((value) => update()); } //TODO: KLUUUUUDGE
        game.fen = data["move_votes"]["fen"];
      }
      else if ((DateTime.timestamp().millisecondsSinceEpoch - lastUpdate) > 5000) {
        ZugModel.log.info("Inconsistent move history, updating...");
        areaCmd(MoleClientMsg.moveHistory);
      }
    }
  }

  void sendMove(String from, String to, String? prom) {
    dc.Move lastMove = chessBoardController.game.history.last.move;
    ZugModel.log.info("Sending move: ${lastMove.fromAlgebraic}${lastMove.toAlgebraic}");
    areaCmd(MoleServMsg.move,data: {  //fieldAreaID : currentArea.title,
      "move" : "${lastMove.fromAlgebraic}${lastMove.toAlgebraic}",
      "promotion" : lastMove.promotion?.name ?? ""
    });
    chessBoardController.undoMove();
  }

  IMap<String, ISet<String>> getLegalMoves() { //print("Generating legal moves for: ${getCurrentGame().fen}");
    chess.load(getCurrentGame().fen);
    Map<String,Set<String>> movelist = {};
    List<dc.Move> moves = chess.generate_moves();
    for (var move in moves) { //print("${move.fromAlgebraic} -> ${move.toAlgebraic}");
      if (movelist.containsKey(move.fromAlgebraic)) {
        movelist[move.fromAlgebraic]?.add(move.toAlgebraic);
      }
      else {
        movelist.putIfAbsent(move.fromAlgebraic, () => {move.toAlgebraic});
      }
    }
    IMap<String,ISet<String>> legalMoves = IMap();
    for (var key in movelist.keys) {
      legalMoves = legalMoves.add(key,movelist[key]!.toSet().toISet());
    } //print(legalMoves);
    return legalMoves;
  }

  String turnString() {
    return getCurrentGame().sideToMove() == SideToMove.black ? "Black" : "White";
  }

  // sets game.orientation (if unset, flips based on getUserSide(user))
  void flipBoard() {
    MoleGame game = getCurrentGame();
    game.orientation = (game.orientation ?? game.getUserSide(userName)) == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
    notifyListeners();
  }

  void handleErrorMessage(data) {
    playClip("doink");
    ZugDialogs.popup("${areas[data[fieldAreaID]]?.id ?? fieldServ}: ${data[fieldMsg]}");
  }

  @override
  void handleUpdateArea(data) { //print("Game Update: ${jsonEncode(data).toString()}");
    if (data["exists"] != true) return;
    super.handleUpdateArea(data);
    MoleGame game = getGame(data); //print("Game Update: $data");
    game.fen = data["currentFEN"] ?? game.fen; //print("Current FEN: ${data["currentFEN"]}");
    if (data["history"] != null) updateMoveHistory(data,game);
    game.updateOccupants(data);
  }

  void updateMoveHistory(data, MoleGame game) {
    if (data["history"] != null) {
      ZugModel.log.info("Updating history: ${game.id}");
      game.moves.clear();
      for (var votes in data["history"]) {
        game.moves.add(votes);
      }
      lastUpdate = DateTime.timestamp().millisecondsSinceEpoch;
    }
  }

  void updateNotifications() { //logMsg(jsonEncode(notifications.toString()));
    send(MoleClientMsg.notify,data: MoleFields.notifications);
  }

  void copyGameLink(MoleGame game) {
    String link = "https://molechess.com?goto=${game.id}";
    Clipboard.setData(ClipboardData(text: link)).then((value) => ZugDialogs.popup("Copied game link to clipboard: $link"));
  }

}

Future<void> initFire() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (kDebugMode) {
    ZugModel.log.info('Permission granted: ${settings.authorizationStatus}');
  }

  String? token = await messaging.getToken();

  pushToken = token;

  final messageStreamController = BehaviorSubject<RemoteMessage>();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (kDebugMode) {
      ZugModel.log.info('Handling a foreground message: ${message.messageId}');
      ZugModel.log.info('Message data: ${message.data}');
      ZugModel.log.info('Message notification: ${message.notification?.title}');
      ZugModel.log.info('Message notification: ${message.notification?.body}');
    }
    messageStreamController.sink.add(message);
    ZugDialogs.popup(message.notification?.body ?? "Unknown notification");
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  ZugModel.log.info("Finished setting up firebase");
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    ZugModel.log.info("Handling a background message: ${message.messageId}");
    ZugModel.log.info('Message data: ${message.data}');
    ZugModel.log.info('Message notification: ${message.notification?.title}');
    ZugModel.log.info('Message notification: ${message.notification?.body}');
  }
  await Firebase.initializeApp();
}
