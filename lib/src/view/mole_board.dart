import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:mole_app/src/mole_dialogs.dart';
import 'package:mole_app/src/view/vote_list.dart';
import 'package:zug_utils/zug_dialogs.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_chat.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_user.dart';
import '../main_page.dart';
import '../mole_model.dart';
import 'mole_clock.dart';
import '../mole_fields.dart';

class CurrentBoardWidget extends StatefulWidget {
  final MoleModel client;
  final List<Widget> headerButtons;
  final Color backgroundColor, foregroundColor;
  final bool landscape;
  final bool hoverMode = false;

  const CurrentBoardWidget(this.client, this.headerButtons, this.landscape, {
    this.foregroundColor = Colors.greenAccent,
    this.backgroundColor = Colors.black,
    super.key});

  @override
  State<StatefulWidget> createState() => CurrentBoardState();
}

class CurrentBoardState extends State<CurrentBoardWidget> {
  final ChessBoardController chessBoardController = ChessBoardController();
  ChessClock? clock;
  double clockSize = 100;
  double moveListWidth = 72; //kIsWeb ? 72 : 50; //TODO: landscape mobile
  double moveListHeight = kIsWeb ? 32 : 48;
  Map<String,dynamic> historySnapshot = {};
  String? hoverFEN;
  ScrollController moveListController = ScrollController();
  //FToast toast = FToast();
  int selectedPly = 0;
  Map<String,dynamic> displayedVotes = {};

  bool _onKey(KeyEvent event) {
    final key = event.logicalKey.keyLabel;
    if (event is KeyDownEvent) { //print("Key down: $key");
      if (key.toLowerCase() == "arrow right") {
        setHistoryPly(selectedPly + 1);
      }
      else if (key.toLowerCase() == "arrow left") {
        setHistoryPly(selectedPly - 1);
      }
    }
    return false;
  }

  void setHistoryPly(int ply) {
    final MoleGame cg = widget.client.getCurrentGame();
    if (ply < 0 || ply == cg.moves.length) {
      selectedPly = cg.moves.length;
      setHistorySnapshot({}, null);
      return;
    }
    else if (ply > cg.moves.length) {
      selectedPly = 0;
    }
     else {
      selectedPly = ply;
    }
    setHistorySnapshot(cg.moves[selectedPly],
        selectedPly > 0 ? cg.moves[selectedPly-1]["fen"]
            : "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
  }

  void setHistorySnapshot(Map<String,dynamic> votes, String? fen) {
    historySnapshot = votes;
    hoverFEN = fen;
    displayedVotes = votes; // Update displayed votes
    if (mounted) setState(() { /* update history */ });
  }

  @override
  void initState() {
    super.initState();
    clock = ChessClock(widget.client,clockSize,clockSize,Colors.brown);
    ServicesBinding.instance.keyboard.addHandler(_onKey);
  }

  @override
  Widget build(BuildContext context) { //toast.init(context);
    final MoleGame cg = widget.client.getCurrentGame();
    widget.client.chessBoardController.loadFen(hoverFEN ?? cg.fen);

    //if (hoverFEN == null) { ZugUtils.scrollDown(moveListController, 250, delay: 750); selectedPly = cg.moves.length; }

    return widget.landscape
        ? buildLandscape(cg, context)
        : buildPortrait(cg, context);
  }

  Widget buildLandscape(MoleGame cg, BuildContext context) {
    return LayoutBuilder(builder: (BuildContext ctx, BoxConstraints bc) {

      double boardSize = bc.maxHeight - MainMolePage.headerHeight;
      double eastWidth = bc.maxWidth - (boardSize + (moveListWidth * 2));
      double statusHeight = boardSize / 4;
      bool statusUnderBoard = false;

      if (eastWidth < 480) {
         boardSize -= statusHeight;
         eastWidth = bc.maxWidth - (boardSize + (moveListWidth * 2));
         statusUnderBoard = true;
      }

      final Widget header = Container(
        color: Colors.black,
        width: boardSize,
        height: MainMolePage.headerHeight,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: widget.headerButtons,
        ),
      );

      final Widget statBox = Container(
        decoration: ZugChat.getDecoration(color: Colors.brown, borderWidth: 0),
        width: statusUnderBoard ? boardSize : eastWidth,
        height: statusHeight,
        child: getStatusWidget(cg, statusUnderBoard ? boardSize : eastWidth, statusHeight, historySnapshot),
      );

      final Widget chatOrVotes = displayedVotes.isNotEmpty
          ? VoteList(displayedVotes, eastWidth, bc.maxHeight)
          : ZugChat(
        widget.client,
        height: bc.maxHeight - statusHeight,
        areaName: "Game",
        serverName: "Lobby",
        borderColor: Colors.grey,
        cmdBkgColor: Colors.brown,
      );

      return Row(
        children: [
          Container(
            color: Colors.black,
            width: boardSize + (moveListWidth * 2),
            child: Column(
              children: [ //const Divider(height: 2),
                header,
                Row(children: [
                    getMoveList(cg,moveListWidth * 2,boardSize),
                    Column(children: [
                      getBoard(cg, boardSize),
                      if (statusUnderBoard) statBox,
                    ]),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(child: chatOrVotes),
                if (!statusUnderBoard) statBox,
              ],
            ),
          )
        ],
      );
    });
  }

  Widget buildPortrait(MoleGame cg, BuildContext context) {
    return LayoutBuilder(builder: (BuildContext ctx, BoxConstraints bc) {

      final Widget statBox = Container(
        decoration: ZugChat.getDecoration(color: Colors.brown, borderWidth: 4),
        child: getStatusWidget(cg, bc.maxWidth, 128, historySnapshot),
      );

      final Widget chatOrVotes = displayedVotes.isNotEmpty
          ? VoteList(displayedVotes, bc.maxWidth, bc.maxHeight)
          : ZugChat(
        widget.client,
        width: bc.maxWidth,
        height: 320,
        areaName: "Game",
        serverName: "Lobby",
        borderColor: Colors.grey,
        cmdBkgColor: Colors.brown,
      );

      return ListView(
        scrollDirection: Axis.vertical,
        children: [getMoveList(cg, bc.maxWidth, moveListHeight * 2), getBoard(cg, bc.maxWidth), statBox, chatOrVotes],
      );

    });
  }

  Widget getBoard(MoleGame game, double boardSize) { //final String fen = hoverFEN ?? game.fen; //print("Generating board: $fen");
    return Container(
        padding: const EdgeInsets.all(3.0),
        color: Colors.grey,
        child: ChessBoard(
      dragHighlightColor: Colors.orange,
      boardColor: BoardColor.values.singleWhere((element) => element.name == widget.client.getOption(MoleOption.boardColors)?.getString(),orElse: () => BoardColor.green),
      pieceSet: widget.client.getOption(MoleOption.pieceSet)?.getString() ?? "mole",
      controller: widget.client.chessBoardController,
      enableUserMoves: hoverFEN == null,
      boardOrientation: game.orientation ?? game.getUserSide(widget.client.userName) ?? PlayerColor.white,
      size: boardSize-6,
      arrows: getArrows(historySnapshot),
      onMove: widget.client.sendMove,
      blackPieceColor: Colors.white,
    ));
  }

  Widget getMoveList(MoleGame cg, double width, double height) {
    List<Widget> rowList = [];
    for (int i=0; i<cg.moves.length; i+=2) {
      rowList.add(Flex(
        direction: widget.landscape ? Axis.horizontal : Axis.vertical,
        children: [
          getMoveBox(i),
          getMoveBox(i+1),
        ],
      ));
    }
    if (cg.moves.length % 2 == 0) rowList.add(getMoveBox(cg.moves.length));
    return MouseRegion(
        onExit: (e) {
          if ((widget.client.prefs?.getBool("movelist_hover") ?? false) && historySnapshot.isNotEmpty) {
            setHistorySnapshot({}, null);
          }
          setState(() {
            displayedVotes = {};
          });
        },
        child: Container(
            color: Colors.black,
            width: width,
            height: height,
            child: ListView(
              scrollDirection: widget.landscape ? Axis.vertical : Axis.horizontal,
              controller: moveListController,
              children: rowList,
            )
        )
    );
  }

  Widget getMoveBox(int ply) {
    MoleGame cg = widget.client.getCurrentGame();
    Map<String,dynamic>? votes = (ply >= 0 && ply < cg.moves.length) ? cg.moves[ply] : null;
    Color txtColor = selectedPly == ply ? Colors.green : Colors.white;
    return Container(
      decoration: ZugChat.getDecoration(color: Colors.black),
      width: moveListWidth,
      height: moveListHeight,
      child: Center(
        child: TextButton(
          onHover: (b) {
            if (widget.hoverMode) {
                setState(() {
                  if (b && votes != null) {
                    displayedVotes = votes;
                  } else {
                    displayedVotes = {};
                  }
                });
            }
          },
          onPressed: () => setHistoryPly(ply),
          child: votes == null
              ? Icon(Icons.refresh, color: txtColor)
              : Text(votes["selected"]["move"]["san"] ?? "?",
              style: TextStyle(color: txtColor)),
        ),
      ),
    );
  }

  List<BoardArrow> getArrows(Map<String,dynamic> votes) { //print("Votes: ${votes.toString()}");
    List<BoardArrow> arrows = [];
    if (votes.isEmpty) return arrows;
      arrows.add(BoardArrow(
        color: HexColor.fromHex(votes['selected'][fieldPlayer][fieldChatColor].toString()).withOpacity(.8),
        from: votes['selected']['move']['from'].toString().toLowerCase(),
        to: votes['selected']['move']['to'].toString().toLowerCase())
    );
    if (votes['alts'] != null) {
      for (Map<String,dynamic> alt in votes['alts']) {
       arrows.add(BoardArrow(
            color: HexColor.fromHex(alt[fieldPlayer][fieldChatColor].toString()).withOpacity(.5),
            from: alt['move']['from'].toString().toLowerCase(),
            to: alt['move']['to'].toString().toLowerCase())
        );
      }
    }
    return arrows;
  }

  ButtonStyle getCommandButtonStyle() {
    return ButtonStyle(
        backgroundColor: WidgetStateColor.resolveWith((states) => Colors.black),
        foregroundColor: WidgetStateColor.resolveWith((states) => Colors.grey)
    );
  }

  Widget getPlaylist(PlayerColor side) {
    MoleGame game = widget.client.getCurrentGame();
    List<Widget> playlist = [];
    for (dynamic player in game.occupantMap.values) { //print(player);
      TextStyle txtStyle = TextStyle(
          color: side == PlayerColor.black ? Colors.white : Colors.black,
          decoration: player["away"] || !player[fieldUser]["logged_in"] ? TextDecoration.lineThrough : TextDecoration.none
      );
      if (colorMap[player[MoleFields.moleFieldSide]] == side)  {
        playlist.add(TextButton(
            onPressed: () {
              ZugDialogs.getValue(ValueDialog(PlayerOptionsDialog(
                  UniqueName.fromData(player[fieldUser]),
                  game,
                  bkgColor: Colors.black,
                  txtColor: HexColor.fromHex(player[fieldChatColor])))
              ).then((action) => widget.client.handlePlayerAction(action));
            },
          child: Center(
            child: Text(
                "${game.parseOccupantName(player[fieldUser])}: "
                "${player["move"]}",
                style: txtStyle),
          ),
        ));
      }
    }
    return ListView(
        scrollDirection: Axis.vertical,
        children: playlist
    );
  }

  Widget getStatusWidget(MoleGame cg, double width, double height, Map<String,dynamic> hoverVotes) {
    double w = (width - (clock?.width ?? 0))/2;
    return SizedBox(width: width, height: height, child: Row( //crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Expanded(
        child: ListView(
            scrollDirection: Axis.horizontal,
            //mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                color: Colors.white,
                width: w,
                height: height,
                child: getPlaylist(PlayerColor.white)),
              Container(
                  color: Colors.black,
                  width: w,
                  height: height,
                  child: getPlaylist(PlayerColor.black)),
            ]),
      ),
      cg.inPhase() ? clock ?? const SizedBox.shrink() : const SizedBox.shrink(),
    ]));
  }
}
