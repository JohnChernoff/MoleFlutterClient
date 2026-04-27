import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:chess/chess.dart' as dc;
import 'package:chessground/chessground.dart' as cg;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' as cb;
import 'package:mole_app/src/view/components/mole_dialogs.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zug_utils/zug_dialogs.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/dialogs.dart';
import 'package:zugclient/zug_app.dart';
import 'package:zugclient/zug_area.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_model.dart';
import 'package:zugclient/zug_option.dart';
import 'package:zugclient/zug_user.dart';
import 'package:mole_app/src/model/mole_game.dart';
import '../../firebase_options.dart';
import 'package:flutter/services.dart';
import '../view/components/role_widget.dart';
import 'mole_fields.dart';
import 'mole_event.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:developer';

//TODO: ZugOptions, Lobby dimensions

class CustomPieceSet {
  String name;
  IMap<cg.PieceKind, AssetImage> pieceSet;
  CustomPieceSet(this.name,this.pieceSet);
}

enum MolePage {
  lobby("lobby"),
  help("fugue"),
  top("scores"),
  events("events"),
  history("clue");
  final String track;
  const MolePage(this.track);
}
enum MoleOption {pieceSet,boardColors,streamerMode}
enum MoleClip {accuse,defect,rampage,bomb,create,doink,moveBlack,moveWhite,vote,roleInspector,roleMole,rolePlayer}
enum MoveVoteDisplay {hide,display,arrows}

class MoleModel extends ZugModel {
  MolePage lobbyPage = MolePage.lobby;
  dc.Chess chess = dc.Chess();
  int lastUpdate = 0;
  List<MoleEvent> events = [];
  List<dynamic> topPlayers = [];
  Map<String,dynamic> playerHistory = {};
  bool confirmAI = false;
  List<CustomPieceSet> customSets = [];
  cb.ChessBoardController chessBoardController = cb.ChessBoardController();
  Map<String,AssetSource> clips = {};
  final GlobalKey boardCaptureKey = GlobalKey();

  MoleModel(super.domain, super.port, super.remoteEndpoint, super.prefs, {super.javalinServer, super.localServer}) {
    modelName = "mole_client";
    areaName = "Mole Game";
    addFunctions({
      ServMsg.ip : handleIP,
      MoleServMsg.move : handleMove,
      MoleServMsg.secrets : handleSecrets,
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
      MoleServMsg.events : handleEvents,
      MoleServMsg.confirmMoveVote : handleVoteMoveConfirmation,
      MoleServMsg.confirmMoveVoteX : handleVoteMoveXConfirmation,
      MoleServMsg.rematching : handleRematching,
      //MoleServMsg.secrets : handleSecret,
      ServMsg.errServMsg : handleError,
    });
    loadChessgroundPieceSets();
    loadOptions([
      (MoleOption.pieceSet,ZugOption(customSets.last.name,label: "Piece Set", enums: List.generate(customSets.length, (i) => customSets.elementAt(i).name))),
      (MoleOption.boardColors,ZugOption(cb.BoardColor.green.name,label: "Board Color",enums:
      List.generate(cb.BoardColor.values.length, (i) => cb.BoardColor.values.elementAt(i).name))),
      (MoleOption.streamerMode,ZugOption(false,label: "Streamer Mode"))
    ]);

    registerEnum<MoveVoteDisplay>(MoveVoteDisplay.values);

    for (MoleClip clip in MoleClip.values) { //print("Loading: ${clip.name}");
      clips.putIfAbsent(clip.name, () => AssetSource("audio/clips/${clip.name}.mp3"));
    }
    //print(waitMap[MoleServMsg.history]);
    //initFire().then((value) {  //_connect(); } );
  }

  handleError(dynamic data) {
    log("Error: $data");
  }

  switchLobbyPage(MolePage p) {
    if (lobbyPage != p) {
      lobbyPage = p;
      playAudio(AssetSource("audio/tracks/${lobbyPage.track}.mp3"));
      notifyListeners();
    }
  }

  @override
  void gotoPage(PageType p) {
      final pp = currentPage.name;
      super.gotoPage(p);
      if (pp != currentPage.name) {
        log("Playing: $currentPage");
        switch(currentPage) {
          case PageType.main:
            playGameTrack(getCurrentGame());
          case PageType.lobby:
            playAudio(AssetSource("audio/tracks/lobby.mp3"));
          case PageType.options:
            playAudio(AssetSource("audio/tracks/fugue.mp3"));
          case PageType.splash:
            playAudio(AssetSource("audio/tracks/splash.mp3"));
          case PageType.none:
            trackPlayer.stop();
        }

      }
  }

  MoleGame getGame(dynamic data) => getOrCreateArea(data) as MoleGame;

  void loadChessgroundPieceSets() {
    for (var set in cg.PieceSet.values) {
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
    return MoleGame(data,onNewPhase: onNewPhase);
  }

  @override
  Future<bool> loggedIn(data) async {
    if (autoJoinTitle == null) {
      int i = math.Random().nextInt(2) + 1;
      ZugDialogs.showClickableDialog(MusicStackDialog(this,"audio/tracks/splash",
          [
            RelativeSizedWidget(Image(image: ZugUtils.getAssetImage("images/mole_dance_bkg${i.toString()}.gif")),1,1),
            RelativeSizedWidget(Image(image: ZugUtils.getAssetImage("images/mole_dance3.gif")),.5,.5),
          ]
      ));
    }
    return super.loggedIn(data);
  }

  @override
  void connected() { //ZugModel.log.info("Connected");
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

  @override
  bool handleErrorMsg(data) {
    log("Error $data");
    return true; //super.handleErrorMsg(data);
  }

  void handleIP(data) {
    ZugModel.log.info("IP Address: ${data[fieldAddress]}");
  }

  MoleGame getCurrentGame() {
    return currentArea as MoleGame;
  }

  void handlePlayerAction(Map<String, dynamic> action) { //print(action);
    if (action[MoleFields.action] == PlayerAction.accuse) {
      ZugDialogs.confirm("Accuse ${action[fieldUniqueName]}?").then((confirmed) {
        if (confirmed) {
          send(MoleClientMsg.voteoff, data: {
            fieldPlayer: action[fieldUniqueName].toJSON(),
            fieldAreaID: action[fieldAreaID]
          });
        }
      });
    }
    else if (action[MoleFields.action] == PlayerAction.kick) {
      ZugDialogs.confirm("Kick ${action[fieldUniqueName]}?").then((confirmed) {
        if (confirmed) {
          send(MoleClientMsg.kickoff, data: {
            fieldPlayer: action[fieldUniqueName].toJSON(),
            fieldAreaID: action[fieldAreaID]
          });
        }
      });
    }
    else if (action[MoleFields.action] == PlayerAction.ban) {
      ZugDialogs.confirm("Ban ${action[fieldUniqueName]}?").then((confirmed) {
        if (confirmed) {
          send(ClientMsg.ban, data: {
            fieldName: action[fieldUniqueName].toJSON(),
            fieldAreaID: action[fieldAreaID]
          });
        }
      });
    }
    else if (action[MoleFields.action] == PlayerAction.finger) {
      send(MoleClientMsg.finger, data: {
        fieldName: action[fieldUniqueName].toJSON(),
      });
    }
    else if (action[MoleFields.action] == PlayerAction.whisper) {
      ZugDialogs.getString("Enter a whisper to ${action[fieldUniqueName]}", "").then((msg) =>
      send(ClientMsg.privMsg, data: {
        fieldName: action[fieldUniqueName].toJSON(),
        fieldMsg: msg
      }));
    }
  }

  void handleVoteMoveConfirmation(data) {
    Area game = getOrCreateArea(data);
    if (game is MoleGame && game == currentArea) {
      addNewMoveVote(game,data['move'],true);
    }
  }

  void handleVoteMoveXConfirmation(data) { //TODO: merge with above
    Area game = getOrCreateArea(data);
    if (game is MoleGame && game == currentArea) {
      addNewMoveVote(game,data['move'],false);
    }
  }

  void handleRematching(data) { //print("Rematching: $data");
    Area game = getOrCreateArea(data);
    game.occupantMap[UniqueName.fromData(data[fieldUser])]["rematching"] = data["rematching"];
  }

  void addNewMoveVote(MoleGame game, String moveStr, bool player) {
    MoveVote vote = MoveVote(moveStr, player);
    game.recentVotes.add(vote);
    Future.delayed(Duration(milliseconds: vote.animationTime + 50)).then((v) {
      game.recentVotes.remove(vote);
      notifyListeners();
    });
  }

  void getTop(int n) {
    send(MoleServMsg.top,data: {"n" : n}, responseType: MoleServMsg.top);
  }

  void handleTop(data) { //print("Top: " + data.toString());
    topPlayers = data;
    if (awaiting(MoleServMsg.top)) switchLobbyPage(MolePage.top);
  }

  void handleFinger(data) {
    ZugDialogs.popup(data.toString());
  }

  Future<void> handlePGN(data) async {
    Clipboard.setData(ClipboardData(text: data[fieldMsg] ?? "?".toString())).then((value) => ZugDialogs.popup("Copied PGN to clipboard"));
  }

  void getPlayerHistory(UniqueName? uName) {
    send(MoleClientMsg.history,data: { fieldPlayer : uName?.toJSON() }, responseType: MoleServMsg.history);
  }

  void handlePlayerHistory(data) {
    playerHistory = data;
    if (awaiting(MoleServMsg.history)) switchLobbyPage(MolePage.history);
  }

  void getEvents() {
    send(MoleClientMsg.events, responseType: MoleServMsg.events);
  }

  void handleEvents(data) {
    events.clear();
    for (dynamic eventData in data) {
      events.add(MoleEvent.fromJson(eventData));
    }
    if (awaiting(MoleServMsg.events)) switchLobbyPage(MolePage.events);
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

  Future<void> handleResult(data) async {
    Area game = getOrCreateArea(data);
    if (game is MoleGame && game == currentArea) {
      game.setResult(data);
      if (game.result != null && game.boardImg == null) {
        log("Capturing game image for result: ${game.result}");
        game.boardImg = await captureWidget(boardCaptureKey);
      }
      //ZugDialogs.showClickableDialog(MusicStackDialog(this,game.getGameTrack(),[MoleDance("Game Over: $winnerString Wins!",moleImg)]));
    }
  }

  bool isStreamerMode() {
    return prefs?.getBool("streamer_mode") ?? defaultStreamerMode;
  }

  void handleSecret(data) {
    ZugDialogs.popup("Secrets: $data");
  }

  void handleSecrets(data) {
    String role = data[MoleFields.role]; //if (game is MoleGame && game == currentArea) {}
    if (isStreamerMode()) {
      addAreaMsg("You are the $role",data[fieldAreaID],hidden: true);
      addAreaMsg("You have ${data[MoleFields.points]} points",data[fieldAreaID],hidden: true);
      addAreaMsg("Secret move: ${data[MoleFields.piece]} -> ${data[MoleFields.square]}",data[fieldAreaID],hidden: true);
      final bountyData = data[MoleFields.bounty];
      if (bountyData != null) {
        final bountyPiece = bountyData[MoleFields.piece];
        final bountySquare = bountyData[MoleFields.square];
        addAreaMsg("Secret Bounty: $bountyPiece on $bountySquare", data[fieldAreaID],hidden: true);
      }
    }
    else {
      playClip("role_${role.toLowerCase()}");
      ZugDialogs.showClickableDialog(SecretCard(roleData: SecretData.fromJson(data)));
    }
  }

  void onNewPhase(MoleGame game) { //print("New Phase: ${game.phase}");
    if (game.phase == MolePhase.postgame) {
      addAreaMsg("Game closing in ${game.phaseTimeRemaining} seconds", game.id);
    }
    if (game == getCurrentGame()) playGameTrack(game);
  }

  void playGameTrack(MoleGame game) {
    playAudio(AssetSource("audio/tracks/${game.getGameTrack()}.mp3"));
  }

  @override
  void handleStart(data) {
    getGame(data).gameState = MoleGameState.playing;
    //TODO: play start music/animation
    return super.handleStart(data);
  }

  void handleMove(data) { //print("New Move: ${jsonEncode(data).toString()}");
    MoleGame game = getGame(data);
    if (currentArea == game) {
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
  }

  void sendMove(String from, String to, String? prom) {
    dc.Move lastMove = chessBoardController.game.history.last.move;
    ZugModel.log.info("Sending move: ${lastMove.fromAlgebraic}${lastMove.toAlgebraic}");
    areaCmd(MoleServMsg.move,data: {  //fieldAreaID : currentArea.title,
      "move" : "${lastMove.fromAlgebraic}${lastMove.toAlgebraic}",
      "promotion" : lastMove.promotion?.name ?? ""
    });
    chessBoardController.undoMove();
    //getCurrentGame().lastVote = MoveVote(lastMove);
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
    game.orientation = (game.orientation ?? game.getUserSide(userName)) == cb.PlayerColor.white ? cb.PlayerColor.black : cb.PlayerColor.white;
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

  Future<ui.Image?> captureWidget(
      GlobalKey key, {
        double pixelRatio = 1.0,
      }) async {
    try {
      final RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      //if (!boundary.isRepainted) { await Future.delayed(const Duration(milliseconds: 100)); }
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      return image;
    } catch (e) {
      log('Error capturing widget: $e');
      return null;
    }
  }

  Future<Uint8List?> captureWidgetAsPNG(
      GlobalKey key, {
        double pixelRatio = 1.0,
      }) async {
    final image = await captureWidget(key, pixelRatio: pixelRatio);
    if (image != null) {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }
    return null;
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
