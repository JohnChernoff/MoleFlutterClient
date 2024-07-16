import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:chess/chess.dart' as dc;
import 'package:chessground/chessground.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:mole_app/src/mole_dialogs.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zugclient/dialogs.dart';
import 'package:zugclient/oauth_client.dart';
import 'package:zugclient/zug_app.dart';
import 'package:zugclient/zug_client.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_utils.dart';
import '../firebase_options.dart';
import 'package:flutter/services.dart';
import 'mole_fields.dart';

class MoleGame extends Area {

  String fen = initialFen;
  dynamic countdown = { //TODO make a class
    "startTime": 0.0,
    "timeStamp": 0.0
  };
  List<dynamic> moves = [];
  List<dynamic> chat = [];
  bool clockRunning = false;
  PlayerColor? orientation;

  MoleGame(dynamic data) : super(data);

  SideToMove sideToMove() {
    return fen.split(" ")[1] == "w" ? SideToMove.white : SideToMove.black;
  }

  PlayerColor? getUserSide(UniqueName? userName) {
    if (userName == null) return null;
    dynamic player = getOccupant(userName);
    if (player == null) return null;
    return colorMap[player[MoleFields.moleFieldSide]];
  }

}

class CustomPieceSet {
  String name;
  IMap<PieceKind, AssetImage> pieceSet;
  CustomPieceSet(this.name,this.pieceSet);
}

class MoleClient extends ZugClient {

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

  MoleClient(super.domain, super.port, super.remoteEndpoint, super.prefs, {super.localServer}) {
    clientName = "mole_client";
    areaName = "Mole Game";
    addFunctions({
      ServMsg.updateArea : handleGameUpdate,
      ServMsg.joinArea : handleJoin,
      ServMsg.partArea : handlePart,
      ServMsg.startArea : handleStartGame,
      ServMsg.ip : handleIP,
      MoleServMsg.move : handleMove,
      //MoleServMsg.status : handleStatus,
      ServMsg.phase : handlePhase,
      MoleServMsg.role : handleRole,
      MoleServMsg.defection : handleDefection,
      MoleServMsg.rampage : handleRampage,
      MoleServMsg.moleBomb : handleMolebomb,
      MoleServMsg.voteList : handleVotelist,
      //MoleServMsg.side : handleSide,
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
    //print(waitMap[MoleServMsg.history]);
    loadChessgroundPieceSets();

    //initFire().then((value) {  //_connect(); } );
  }

  void loadChessgroundPieceSets() {
    for (var set in PieceSet.values) {
      customSets.add(CustomPieceSet(set.name, set.assets));
    }
    customSets.add(CustomPieceSet("mole", MoleFields.moleSet));
  }

  @override
  void send(Enum type, { var data = "" }) {
    //ZugClient.log.info("Sending: ${type.name}, data: $data");
    super.send(type, data: data);
  }

  @override
  Enum handleMsg(String msg) {
    Enum e = super.handleMsg(msg);
    //ZugClient.log.info("Received: $e");
    return e;
  }

  @override
  void startArea() {
    Dialogs.getValue(const ValueDialog(TimeSelectDialogOptions()))
        .then((value) => areaCmd(ClientMsg.startArea, data: {"time" : value}));
  }

  @override
  Area createArea(dynamic data) {
    return MoleGame(data);
  }

  @override
  bool loggedIn(data) {
    if (autoJoinTitle == null) {
      int i = Random().nextInt(2) + 1;
      Dialogs.showClickableDialog(MusicStackDialog(this,"mole_intro1",
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
    ZugClient.log.info("Connected");
    super.connected();
    send(MoleClientMsg.version);
    checkRedirect(OauthClient("lichess.org",clientName));
  }

  @override
  void handleVersion(data) {
    super.handleVersion(data);
    ZugUtils.getIP().then((address) => send(ClientMsg.ip,data: {fieldAddress : address}));
    //send(ClientMsg.ip,data: {fieldAddress : Random().nextInt(255).toString()});
  }

  void handleIP(data) {
    ZugClient.log.info("IP Address: ${data[fieldAddress]}");
  }

  MoleGame getCurrentGame() {
    return currentArea as MoleGame;
  }

  void handlePlayerAction(Map<String, dynamic> action) { //print(action);
    if (action["action"] == PlayerAction.accuse) {
      Dialogs.confirm("Accuse ${action["playerName"]}?").then((confirmed) {
        if (confirmed) {
          send(MoleClientMsg.voteoff, data: {
            fieldPlayer: action["playerName"].toJSON(),
            fieldTitle: action["gameTitle"]
          });
        }
      });
    }
    else if (action["action"] == PlayerAction.kick) {
      Dialogs.confirm("Kick ${action["playerName"]}?").then((confirmed) {
        if (confirmed) {
          send(MoleClientMsg.kickoff, data: {
            fieldPlayer: action["playerName"].toJSON(),
            fieldTitle: action["gameTitle"]
          });
        }
      });
    }
    else if (action["action"] == PlayerAction.ban) {
      Dialogs.confirm("Ban ${action["playerName"]}?").then((confirmed) {
        if (confirmed) {
          send(ClientMsg.ban, data: {
            fieldName: action["playerName"].toJSON(),
            fieldTitle: action["gameTitle"]
          });
        }
      });
    }
    else if (action["action"] == PlayerAction.finger) {
      send(MoleClientMsg.finger, data: {
        fieldName: action["playerName"].toJSON(),
      });
    }
    else if (action["action"] == PlayerAction.whisper) {
      Dialogs.getString("Enter a whisper to ${action["playerName"]}", "").then((msg) =>
      send(ClientMsg.privMsg, data: {
        fieldName: action["playerName"].toJSON(),
        fieldMsg: msg
      }));
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
      ZugClient.log.info('Permission granted: ${settings.authorizationStatus}');
    }

    String? token = await messaging.getToken();

    pushToken = token;

    final messageStreamController = BehaviorSubject<RemoteMessage>();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        ZugClient.log.info('Handling a foreground message: ${message.messageId}');
        ZugClient.log.info('Message data: ${message.data}');
        ZugClient.log.info('Message notification: ${message.notification?.title}');
        ZugClient.log.info('Message notification: ${message.notification?.body}');
      }
      messageStreamController.sink.add(message);
      Dialogs.popup(message.notification?.body ?? "Unknown notification");
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    ZugClient.log.info("Finished setting up firebase");
  }

  void getTop(int n) {
    waitMap[MoleServMsg.top] = Completer();
    send(MoleServMsg.top,data: {"n" : n});
  }

  void handleTop(data) { //print("Top: " + data.toString());
    topPlayers = data;
    waitMap[MoleServMsg.top]?.complete();
  }

  void handleFinger(data) {
    Dialogs.popup(data.toString());
  }

  Future<void> handlePGN(data) async {
    Clipboard.setData(ClipboardData(text: data[fieldMsg] ?? "?".toString())).then((value) => Dialogs.popup("Copied PGN to clipboard"));
  }

  void getPlayerHistory(UniqueName? uName) {
    waitMap[MoleServMsg.history] = Completer();
    send(MoleClientMsg.history,data: { fieldPlayer : uName?.toJSON() });
  }

  void handlePlayerHistory(data) {
    playerHistory = data;
    if (waitMap[MoleServMsg.history] != null) {
      ZugClient.log.info("Waiting on history");
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
      playClip("defect");
      Dialogs.popup("${ZugUtils.getOccupantName(data)} defects!",
          imgFile: "defection.png");
    }
  }

  void handleRampage(data) { //print("Rampage: $data");
    Area game = getOrCreateArea(data);
    if (game is MoleGame && game == currentArea) {
      playClip("rampage");
      Dialogs.popup("${ZugUtils.getOccupantName(data)} rampages!",
          imgFile: "rampage.png");
    }
  }

  void handleMolebomb(data) {
    Area game = getOrCreateArea(data);
    if (game is MoleGame && game == currentArea) {
      playClip("bomb");
      Dialogs.popup("${ZugUtils.getOccupantName(data)} bombs!",
          imgFile: "molebomb.png");
    }
  }

  void handleStartGame(data) {
    switchPage = PageType.main;
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

      PlayerColor? side = game.getUserSide(user);
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

      Dialogs.showClickableDialog(
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
      addAreaMsg("You are the $role",data[fieldTitle],hidden: true);
    }
    else {
      playClip("role_${role.toLowerCase()}");
      Dialogs.popup("You are the $role",imgFile: "${role.toLowerCase()}.png");
    }
  }

  void handleJoin(data) { //print("Joining");
    handleGameUpdate(data);
    switchArea(data[fieldTitle]);
  }

  void handlePart(data) { //print("Parting");
    handleGameUpdate(data); //switchArea(null);
  }

  void handlePhase(data) {
    handleGameUpdate(data);
    if (data["phase"] == "POSTGAME") {
      addAreaMsg(
          "Game closing in ${data["timeRemaining"]} seconds",
          data[fieldTitle]
      );
    }
    //handleAreaChange({fieldAreaChange : AreaChange.updated, fieldArea : data});
  }

  void handleMove(data) { //print("New move: ${data['move']}");
    Area game = getOrCreateArea(data);
    if (game is MoleGame && game == currentArea) {
      playClip(game.sideToMove() == SideToMove.black ? "move_black" : "move_white"); //TODO: fix NPE
      if (data["move_votes"] != null) {
        if (game.moves.length + 1 == data["ply"]) {
          game.moves.add(data["move_votes"]);
          //if (kIsWeb) {  Future.delayed(const Duration(milliseconds: 250)).then((value) => update()); } //TODO: KLUUUUUDGE
        }
        else if ((DateTime.timestamp().millisecondsSinceEpoch - lastUpdate) > 5000) {
          ZugClient.log.info("Inconsistent move history, updating...");
          send(ServMsg.updateArea,data:game.title);
        }
      }
    }
  }

  void sendMove() {
    dc.Move lastMove = chessBoardController.game.history.last.move;
    ZugClient.log.info("Sending move: ${lastMove.fromAlgebraic}${lastMove.toAlgebraic}");
    send(MoleServMsg.move,data: {
      fieldTitle : currentArea.title,
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
    game.orientation = (game.orientation ?? game.getUserSide(user)) == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
    notifyListeners();
  }

  void handleErrorMessage(data) {
    final source = areas[data[fieldTitle]]?.title ?? fieldServ;
    playClip("doink");
    Dialogs.popup("$source: ${data[fieldMsg]}");
  }

  void handleGameUpdate(data) { //print("Game Update: ${jsonEncode(data).toString()}");
    if (data["exists"] != true) return;
    Area game = getOrCreateArea(data); //print("Game Update: $data");
    if (game is MoleGame) { //&& game == currentArea) {
      game.fen = data["currentFEN"] ?? game.fen; //print("Current FEN: ${data["currentFEN"]}");
      final timeRemaining = double.tryParse(data["timeRemaining"].toString());
      if (timeRemaining != null && timeRemaining > 0) {
        game.clockRunning = true; //TODO: move to handleGameStart
        game.countdown["startTime"] = timeRemaining;
        game.countdown["timeStamp"] = DateTime.now().millisecondsSinceEpoch.toDouble(); //Android wants all js stuff to be double
      }
      if (data["history"] != null) updateMoveHistory(data,game);
      game.updateOccupants(data);
    }
  }

  dynamic getCurrentTime() {
    MoleGame game = getCurrentGame();
    double t = game.countdown["startTime"] - ((DateTime.now().millisecondsSinceEpoch - game.countdown["timeStamp"])/1000);
    double p = t > 0 ? (t/game.countdown["startTime"]) : 0;
    return {
      "time" : t,
      "progress" : p.isFinite ? p : 0
    };
  }

  void updateMoveHistory(data, MoleGame game) {
    if (data["history"] != null) {
      ZugClient.log.info("Updating history: ${game.title}");
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

//void sendChat(String msg, bool lobby) { send("chat",data: { "msg": msg, "source": lobby ? servString : currentGame.title }); }

  void copyGameLink(MoleGame game) {
    String link = "https://molechess.com?goto=${game.title}";
    Clipboard.setData(ClipboardData(text: link)).then((value) => Dialogs.popup("Copied game link to clipboard: $link"));
  }

}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    ZugClient.log.info("Handling a background message: ${message.messageId}");
    ZugClient.log.info('Message data: ${message.data}');
    ZugClient.log.info('Message notification: ${message.notification?.title}');
    ZugClient.log.info('Message notification: ${message.notification?.body}');
  }
  await Firebase.initializeApp();
}
