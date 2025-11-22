import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:mole_app/main.dart';
import 'package:mole_app/src/view/components/mole_dialogs.dart';
import 'package:mole_app/src/view/components/vote_list.dart';
import 'package:mole_app/src/view/components/rematch_widget.dart';
import 'package:zug_utils/zug_dialogs.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_chat.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_user.dart';
import '../components/mole_menu.dart';
import '../../model/mole_model.dart';
import '../components/mole_clock.dart';
import '../../model/mole_fields.dart';
import 'package:mole_app/src/model/mole_game.dart';

class CurrentGameWidget extends StatefulWidget {
  final MoleModel client;
  final Color backgroundColor, foregroundColor;
  final bool hoverMode = true;

  const CurrentGameWidget(this.client, {
    this.foregroundColor = Colors.greenAccent,
    this.backgroundColor = Colors.black,
    super.key});

  @override
  State<StatefulWidget> createState() => CurrentGameState();
}

class CurrentGameState extends State<CurrentGameWidget> {
  final ChessBoardController chessBoardController = ChessBoardController();
  ChessClock? clock;
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
    clock = ChessClock(widget.client, 100, 100, Colors.brown);
    ServicesBinding.instance.keyboard.addHandler(_onKey);
  }

  @override
  Widget build(BuildContext context) { //toast.init(context);

    final MoleGame cg = widget.client.getCurrentGame();
    widget.client.chessBoardController.loadFen(hoverFEN ?? cg.fen);
    //if (hoverFEN == null) { ZugUtils.scrollDown(moveListController, 250, delay: 750); selectedPly = cg.moves.length; }

    return LayoutBuilder(builder: (BuildContext ctx, BoxConstraints bc) {
      return bc.maxWidth > bc.maxHeight ? buildLandscape(cg, context, bc) : buildPortrait(cg, context, bc);
    });

  }

  Widget buildLandscape(MoleGame cg, BuildContext context, BoxConstraints bc) {
    double boardSize = bc.maxHeight - MoleApp.headerHeight;
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
      height: MoleApp.headerHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: getBoardHeaderButtons(widget.client,bc.maxHeight),
      ),
    );

    double topMargin = 1;
    final Widget statBox = Container(
      margin: EdgeInsets.only(top: topMargin),
      decoration: BoxDecoration(
        color: Colors.brown,
        border: Border.symmetric(vertical: BorderSide(color: Colors.grey[800]!, width: 2)),
        borderRadius: BorderRadius.circular(8),
      ),
      width: statusUnderBoard ? boardSize : eastWidth,
      height: statusHeight - topMargin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: getStatusWidget(cg,
            statusUnderBoard ? boardSize : eastWidth,
            statusHeight - topMargin,
            historySnapshot),
      ),
    );

    final Widget chatOrVotes = //Padding(padding: EdgeInsets.only(right: 4, top: 4), child:
    Stack(children: [
      ZugChat(
        widget.client,
        height: bc.maxHeight - statusHeight,
        areaName: "Game",
        serverName: "Lobby",
        borderColor: Colors.grey,
        cmdBkgColor: Colors.brown,
      ),
      if (displayedVotes.isNotEmpty) VoteList(displayedVotes, eastWidth, bc.maxHeight)
    ]);

    return Row(
      children: [
        Container(
          color: Colors.black,
          width: boardSize + (moveListWidth * 2),
          child: Column(
            children: [ //const Divider(height: 2),
              header,
              Row(children: [
                getMoveList(cg,moveListWidth * 2,boardSize, true),
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
              if (!statusUnderBoard) statBox, //Padding(padding: EdgeInsets.only(top: 4, left: 0, right: 4), child: statBox),
            ],
          ),
        )
      ],
    );
  }

  Widget buildPortrait(MoleGame cg, BuildContext context, BoxConstraints bc) {
    //List<Widget> headButts = getBoardHeaderButtons(widget.client,bc.maxWidth);
    final Widget statBox = Container( //decoration: ZugChat.getDecoration(color: Colors.brown, borderWidth: 4),
      color: Colors.brown,
      child: getStatusWidget(cg, bc.maxWidth, 128, historySnapshot),
    );

    final Widget chatOrVotes =  displayedVotes.isNotEmpty
        ? VoteList(displayedVotes, bc.maxWidth, bc.maxHeight)
        : ZugChat(
      widget.client,
      width: bc.maxWidth,
      areaName: "Game",
      serverName: "Lobby",
      borderColor: Colors.grey,
      cmdBkgColor: Colors.brown,
    );

    return SingleChildScrollView(child: SizedBox(width: bc.maxWidth, height: bc.maxHeight, child: Column(
      children: [
        getMoveList(cg, bc.maxWidth, moveListHeight * 2, false),
        getBoard(cg, bc.maxWidth),
        statBox,
        Expanded(child: chatOrVotes)],
    )));
  }

  Widget getBoard(MoleGame game, double boardSize) {
    return Container(
      width: boardSize,
      height: boardSize,
      padding: const EdgeInsets.all(3.0),
      color: Colors.grey,
      child: Stack(
        alignment: AlignmentGeometry.center,
        children: [
          switch (game.status) {
            MoleGameStatus.pregame => getChessBoard(game, boardSize),
            MoleGameStatus.playing => getChessBoard(game, boardSize),
            MoleGameStatus.finished => RematchWidget(game, userName: widget.client.userName,
                onRematch: () => ZugDialogs.confirm("Begin Rematch?").then((b) => {
                  if (b) widget.client.areaCmd(MoleClientMsg.rematch)
                }),
                onRematching: () => widget.client.areaCmd(MoleClientMsg.rematching),
                board: getChessBoard(game, boardSize/2),size: boardSize),
            null => getChessBoard(game, boardSize),
          },
        ],
      ),
    );
  }

  Widget getChessBoard(MoleGame game, double boardSize) {
    return RepaintBoundary(key: widget.client.boardCaptureKey, child: ChessBoard(
      dragHighlightColor: Colors.orange,
      boardColor: BoardColor.values.singleWhere(
            (element) => element.name == widget.client.getOption(MoleOption.boardColors)?.getString(),
        orElse: () => BoardColor.green,
      ),
      pieceSet: widget.client.getOption(MoleOption.pieceSet)?.getString() ?? "mole",
      controller: widget.client.chessBoardController,
      enableUserMoves: hoverFEN == null,
      boardOrientation: game.orientation ?? game.getUserSide(widget.client.userName) ?? PlayerColor.white,
      size: boardSize - 6,
      arrows: game.recentVotes.isNotEmpty
          ? List.generate(game.recentVotes.length, (i) {
        MoveVote vote = game.recentVotes.elementAt(i);
        return BoardArrow(from: vote.move.from, to: vote.move.to, color: vote.player ? Colors.blue.withValues(alpha: 77) : Color.fromARGB(77, 222, 55, 0)
        );
      })
          : getArrows(historySnapshot),
      onMove: widget.client.sendMove,
      blackPieceColor: Colors.white,
    ));
  }

  Widget getMoveList(MoleGame cg, double width, double height, bool landscape) {
    List<Widget> rowList = [];
    for (int i=0; i<cg.moves.length; i+=2) {
      rowList.add(Flex(
        direction: landscape ? Axis.horizontal : Axis.vertical,
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
          if (landscape) {
            setState(() {
              displayedVotes = {};
            });
          }
        },
        child: Container(
            color: Colors.black,
            width: width,
            height: height,
            child: ListView(
              scrollDirection: landscape ? Axis.vertical : Axis.horizontal,
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

    // Cyan highlight for current position
    final isLive = votes == null;
    final borderDecoration = isLive
        ? BoxDecoration(
      border: Border.all(color: Colors.cyan, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.cyan.withOpacity(0.4),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
    )
        : BoxDecoration();

    return Container(
      decoration: ZugChat.getDecoration(color: Colors.black),
      width: moveListWidth,
      height: moveListHeight,
      child: Container(
        decoration: borderDecoration,
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
            child: isLive
                ? Icon(Icons.videocam_outlined, color: Colors.cyan, size: 24)
                : Text(
              votes["selected"]["move"]["san"] ?? "?",
              style: TextStyle(color: txtColor),
            ),
          ),
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
      if (colorMap[player[MoleFields.side]] == side)  {
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
    double w2 = width / 5;
    double w = w2 * 2;
    if ((clock?.width ?? w2) != w2) {
      clock = ChessClock(widget.client,w2,w2,Colors.brown);
    }
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
      cg.inPhase ? clock ?? const SizedBox.shrink() : const SizedBox.shrink(),
    ]));
  }
}
