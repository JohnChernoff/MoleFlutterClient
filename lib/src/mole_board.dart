import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mole_app/src/mole_dialogs.dart';
import 'package:zugclient/dialogs.dart';
import 'package:zugclient/zug_chat.dart';
import 'package:zugclient/zug_client.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_utils.dart';
import 'main_page.dart';
import 'mole_client.dart';
import 'mole_clock.dart';
import 'mole_fields.dart';

class CurrentBoardWidget extends StatefulWidget {
  final MoleClient client;
  final List<Widget> headerButtons;
  final Color backgroundColor, foregroundColor;
  final bool landscape;

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
  FToast toast = FToast();
  int selectedPly = 0;

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

  void setHistorySnapshot(Map<String,dynamic> votes, String? fen) { //print("Hovering: $fen");
    historySnapshot = votes;
    hoverFEN = fen;
    if (mounted) setState(() { /* update history */  }); //if (kIsWeb) {  Future.delayed(const Duration(milliseconds: 50)).then((value) => widget.client.update()); }
  }

  @override
  void initState() {
    super.initState();
    clock = ChessClock(widget.client,clockSize,clockSize,Colors.brown);
    ServicesBinding.instance.keyboard.addHandler(_onKey);
  }

  @override
  Widget build(BuildContext context) {
    toast.init(context);
    final MoleGame cg = widget.client.getCurrentGame();
    widget.client.chessBoardController.loadFen(hoverFEN ?? cg.fen);

    if (hoverFEN == null) {
      ZugUtils.scrollDown(moveListController,250,delay : 750);
      selectedPly = cg.moves.length;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = ZugUtils.getActualScreenHeight(context);
    double boardSize = widget.landscape ? (screenHeight - MainMolePage.headerHeight) : screenWidth;
    double? statusHeight = widget.landscape ? max(clockSize,(screenHeight / 4)) : null;

    Container statBox = Container(
      decoration: ZugChat.getDecoration(color: Colors.brown, borderWidth: widget.landscape ? 0 : 4),
      height: statusHeight,
      child: getStatusWidget(cg,
          widget.landscape ? screenWidth - (boardSize + (moveListWidth * 2)) : boardSize,
          statusHeight ?? clockSize,historySnapshot),
    );

    final Widget chatBox = ZugChat(
        widget.client,
        width: (widget.landscape ? null : screenWidth),
        height: screenHeight - (statusHeight ?? 0),
        serverName: "General",
    );

    return widget.landscape
        ? Row(
            children: [
              westSide(cg, screenWidth, boardSize, const SizedBox.shrink()),
              Expanded(
                  child: Column(
                children: [
                  Expanded(child: chatBox),
                  statBox,
                ],
              ))
            ],
          )
        : ListView(
            scrollDirection: Axis.horizontal,
            children: [westSide(cg, screenWidth, boardSize, statBox), chatBox],
          );
  }

  Widget westSide(MoleGame cg, double screenWidth, double boardSize, Widget footer) {
    Container header = Container(
        color: Colors.black,
        width: screenWidth,
        height: widget.landscape ? null : MainMolePage.headerHeight,
        child: ListView(
            scrollDirection: Axis.horizontal,
            children: widget.headerButtons
        )
    );
    return Container(
      color: widget.backgroundColor,
      width: boardSize + (widget.landscape ? moveListWidth * 2 : 0),
      child: Column(
        //mainAxisAlignment: MainAxisAlignment.start,
        //crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 2),
          widget.landscape ? Expanded(child: header) : header,
          Flex(
            direction: widget.landscape ? Axis.horizontal : Axis.vertical,
            children: [
              MouseRegion(
                  onExit: (e) {
                    if ((widget.client.prefs?.getBool("movelist_hover") ?? false) && historySnapshot.isNotEmpty) {
                      setHistorySnapshot({},null);
                    }
                  },
                  child: getMoveList(boardSize)
              ),
              getBoard(cg,boardSize),
            ],
          ),
          widget.landscape ? footer : Expanded(child: footer),
        ],
      ),
    );
  }

  Widget getBoard(MoleGame game, double boardSize) {
    int pieceSet = widget.client.prefs?.getInt("piece_set") ?? defaultPieceSetIndex;
    BoardColor boardColor = BoardColor.values.singleWhere((element) => element.name.toLowerCase() == widget.client.prefs?.getString("board_colors"),orElse: () => defaultBoardColor);
    //final String fen = hoverFEN ?? game.fen; //print("Generating board: $fen");
    return ChessBoard(
      dragHighlightColor: Colors.orange,
      boardColor: boardColor,
      pieceSet: widget.client.customSets[pieceSet].name.toLowerCase(),
      controller: widget.client.chessBoardController,
      enableUserMoves: hoverFEN == null,
      boardOrientation: game.orientation ?? game.getUserSide(widget.client.user) ?? PlayerColor.white,
      size: boardSize,
      arrows: getArrows(historySnapshot),
      onMove: widget.client.sendMove,
    );
  }

  Widget getMoveList(double boardSize) {
    MoleGame cg = widget.client.getCurrentGame();
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
    return Container(
        color: Colors.brown,
        width: widget.landscape ? moveListWidth * 2 : boardSize,
        height: widget.landscape ? boardSize : moveListHeight * 2,
        child: ListView(
          scrollDirection: widget.landscape ? Axis.vertical : Axis.horizontal,
          controller: moveListController,
          children: rowList,
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
        child: Center(child: TextButton(
            onHover: (b) {
                if (b && votes != null) {
                  showToast(votes);
                } else {
                  toast.removeCustomToast();
                  toast.removeQueuedCustomToasts();
                }
              },
              onPressed: () => setHistoryPly(ply),
            child: votes == null
                ? Icon(Icons.refresh,color: txtColor) //const Text("*",style: TextStyle(color: Colors.white))
                : Text(votes["selected"]["move"]["san"] ?? "?",style: TextStyle(color: txtColor))),
        ));
  }

  void showToast(Map<String,dynamic> votes) {
    Widget toastTxt = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.greenAccent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: parseMoveVotes(votes,txtColor: Colors.black),
      ),
    );

    // Custom Toast Position
    toast.showToast(
        child: toastTxt,
        toastDuration: const Duration(seconds: 2),
        positionedToastBuilder: (context, child) {
          return Positioned(
            top: 16.0,
            left: 16.0,
            child: child,
          );
        });
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
        backgroundColor: MaterialStateColor.resolveWith((states) => Colors.black),
        foregroundColor: MaterialStateColor.resolveWith((states) => Colors.grey)
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
              Dialogs.getValue(ValueDialog(PlayerOptionsDialog(
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

  List<Widget> parseMoveVotes(Map<String,dynamic> votes, {Color? txtColor}) {
    List<Widget> voteList = [];
    if (votes.isNotEmpty) { //print(hoverVotes);
      voteList.add(
          Text("${ZugUtils.getUserName(votes['selected'][fieldPlayer][fieldUser])}: ${votes['selected']['move']['san']}",
              style: TextStyle(color: txtColor ?? HexColor.fromHex(votes['selected'][fieldPlayer][fieldChatColor])))
      );
      if (votes['alts'] != null) {
        for (Map<String,dynamic> alt in votes['alts']) {
          voteList.add(
              Text("${ZugUtils.getUserName(alt[fieldPlayer][fieldUser])}: ${alt['move']['san']}",
                  style: TextStyle(color: txtColor ?? HexColor.fromHex(alt[fieldPlayer][fieldChatColor])))
          );
        }
      }
    }
    return voteList;
  }

  Widget getStatusWidget(MoleGame cg, double width, double height, Map<String,dynamic> hoverVotes) {
    List<Widget> hoverMoves = parseMoveVotes(hoverVotes); //double w = ((width - (widget.landscape ? moveListWidth : 0)) - (clock?.width ?? 0))/2;
    double w = (width - (clock?.width ?? 0))/2;
    return Row( //crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Expanded(
        child: ListView(
            scrollDirection: Axis.horizontal,
            //mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                color: hoverMoves.isEmpty ? Colors.white : Colors.black,
                width: w,
                height: height,
                child: hoverMoves.isEmpty
                    ? getPlaylist(PlayerColor.white)
                    : const SizedBox.shrink(),
              ),
              Container(
                  color: Colors.black,
                  width: w,
                  height: height,
                  child: hoverMoves.isEmpty
                      ? getPlaylist(PlayerColor.black)
                      : Center(
                          child: ListView(
                              scrollDirection: Axis.vertical,
                              children: hoverMoves))),
            ]),
      ),
      cg.clockRunning ? clock ?? const SizedBox.shrink() : const SizedBox.shrink(),
    ]);
  }
}
