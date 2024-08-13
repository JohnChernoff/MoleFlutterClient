import 'package:flutter/cupertino.dart';
import 'package:zugclient/zug_utils.dart';
import 'mole_board.dart';
import 'mole_client.dart';
import 'package:flutter/material.dart';
import 'mole_fields.dart';
import 'mole_history.dart';
import 'mole_scores.dart';

enum MainPages { currentBoard,scorePage, historyPage }

class MainMolePage extends StatefulWidget {
  static const double headerHeight = 36;
  final MoleClient client;
  const MainMolePage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => MainMolePageState();
}

class MainMolePageState extends State<MainMolePage> {
  MainPages page = MainPages.currentBoard;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = ZugUtils.getActualScreenHeight(context);
    final bool landscape = screenWidth > screenHeight;
    final Widget board = CurrentBoardWidget(widget.client,getBoardHeaderButtons(landscape ? screenHeight : screenWidth),landscape);

    return switch (page) {
        MainPages.currentBoard => board, //TODO: scrollController
        MainPages.scorePage => MoleScorePage(widget.client,getBoardHeaderButtons(screenWidth)),
        MainPages.historyPage => PlayerHistoryPage(widget.client,getBoardHeaderButtons(screenWidth))
      };
  }

  List<Widget> getBoardHeaderButtons(double width, {iconColor = Colors.grey}) {
    bool shortWidth = width < 720;
    if (page != MainPages.currentBoard) {
      return [
        ElevatedButton(
          style: getCommandButtonStyle(),
          onPressed: () {
            setState(() { page = MainPages.currentBoard; });
          },
          child: Icon(Icons.arrow_back, color: iconColor),
        )
      ];
    }
    return [
      ElevatedButton(
          style: getCommandButtonStyle(),
          onPressed: () async {
            widget.client.getTop(10);
            while (widget.client.topPlayers.isEmpty) {
              await Future.delayed(const Duration(seconds: 1));
            }
            setState(() {
              page = MainPages.scorePage;
            });
          },
          child: Row(
            children: [
              Icon(Icons.score, color: iconColor),
              shortWidth ? const SizedBox.shrink() : const Text(" Scores"),
            ],
          )),
      ElevatedButton(
          style: getCommandButtonStyle(),
          onPressed: () {
            widget.client.getPlayerHistory(widget.client.userName);
            widget.client.waitMap[MoleServMsg.history]?.future
                .then((value) => setState(() {
                      page = MainPages.historyPage;
                    }));
          },
          child: Row(
            children: [
              Icon(Icons.location_history_rounded, color: iconColor),
              shortWidth ? const SizedBox.shrink() : const Text(" History"),
            ],
          )),
      ElevatedButton(
          style: getCommandButtonStyle(),
          onPressed: () {
            widget.client.areaCmd(MoleClientMsg.role);
          },
          child: Row(
            children: [
              const Icon(Icons.info),
              shortWidth ? const SizedBox.shrink() : const Text(" Role"),
            ],
          )),
      ElevatedButton(
          style: getCommandButtonStyle(),
          onPressed: () {
            widget.client.flipBoard();
          },
          child: Row(
            children: [
              const Icon(CupertinoIcons.arrow_up_left_arrow_down_right),
              shortWidth ? const SizedBox.shrink() : const Text(" Flip"),
            ],
          )),
      ElevatedButton(
        style: getCommandButtonStyle(),
        onPressed: () {
          widget.client.areaCmd(MoleClientMsg.draw);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.equal_circle),
            shortWidth ? const SizedBox.shrink() : const Text(" Draw"),
          ],
        ),
      ),
      ElevatedButton(
        style: getCommandButtonStyle(),
        onPressed: () {
          widget.client.areaCmd(MoleClientMsg.resign);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag),
            shortWidth ? const SizedBox.shrink() : const Text(" Resign"),
          ],
        ),
      ),
      ElevatedButton(
        style: getCommandButtonStyle(),
        onPressed: () {
          widget.client.areaCmd(MoleClientMsg.veto, data: {"confirm": true});
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cancel),
            shortWidth ? const SizedBox.shrink() : const Text(" Veto"),
          ],
        ),
      ),
      ElevatedButton(
        style: getCommandButtonStyle(),
        onPressed: () {
          widget.client.areaCmd(MoleClientMsg.inspect);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.search), //Icons.find_replace),
            shortWidth ? const SizedBox.shrink() : const Text(" Inspect"),
          ],
        ),
      ),
      ElevatedButton(
        style: getCommandButtonStyle(),
        onPressed: () {
          widget.client.areaCmd(MoleClientMsg.pgn);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download), //Icons.find_replace),
            shortWidth ? const SizedBox.shrink() : const Text(" PGN"),
          ],
        ),
      ),
    ];
  }

  ButtonStyle getCommandButtonStyle() {
    return ButtonStyle(
        backgroundColor: MaterialStateColor.resolveWith((states) => Colors.black),
        foregroundColor: MaterialStateColor.resolveWith((states) => Colors.grey)
    );
  }
}


