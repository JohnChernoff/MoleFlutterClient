import 'dart:convert';
import 'package:chessground/chessground.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:zugclient/zug_client.dart';
import 'main_page.dart';
import 'mole_client.dart';
import 'package:chess/chess.dart' as dc;
import 'dart:js' as js;

class PlayerHistoryPage extends StatefulWidget {
  final MoleClient client;
  final List<Widget> headButts;
  const PlayerHistoryPage(this.client, this.headButts, {super.key});

  @override
  State<StatefulWidget> createState() => _PlayerHistoryPage();
}

class _PlayerHistoryPage extends State<PlayerHistoryPage> {
  late GridView pgnList;

  @override
  void initState() {
    ZugClient.log.info("Initializing History: ${widget.client.playerHistory["player_data"].toString()}");
    // TODO: implement initState
    super.initState();

    pgnList = GridView(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        children: List.generate(widget.client.playerHistory["pgn_list"].length, (index) => PGNViewer(
            widget.client.playerHistory["pgn_list"][index]["pgn"].toString()
        )));
  }

  @override
  Widget build(BuildContext context) { //print(widget.client.playerHistory);
    final double screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Container(
            color: Colors.black,width: screenWidth,height: MainMolePage.headerHeight,
            child: ListView(
                scrollDirection: Axis.horizontal,
                children: widget.headButts)),
        Text(widget.client.playerHistory["player_data"].toString()),
        Expanded(
            child: Container(
              color: Colors.black,
              child: pgnList,
            )),
      ],
    );
  }
}

class PGNViewer extends StatefulWidget {
  final String pgn;
  const PGNViewer(this.pgn, {super.key});

  @override
  State<StatefulWidget> createState() => _PGNViewer();
}

class _PGNViewer extends State<PGNViewer> {
  final TextStyle textStyle = const TextStyle(color: Colors.white);
  List<dynamic> history = [];
  int ply = 0;
  dynamic headers = {}; //Map<String,String>

  @override
  void initState() {
    super.initState();

    final pgnGame = jsonDecode(js.context.callMethod("parsePgn", [widget.pgn])); //print(pgnGame);
    dc.Chess game = dc.Chess(); //game.load_pgn(widget.pgn);
    headers = pgnGame["tags"]; //print(headers.toString());

    for (dynamic move in pgnGame["moves"]) {
      final comment = move["commentDiag"]["comment"] ?? "";
      final san = move["notation"]["notation"]; //print(san);
      if (san != null) {
        game.move(san);
        history.add({
          "fen": game.fen,
          "comment": comment,
          "arrows": getArrows(move["commentDiag"]["colorArrows"])
        });
      }
    }
  }

  Shape getArrow(String txt) {
    final color = switch(txt.substring(0, 1)) {
      "R" => Colors.red,
      "G" => Colors.green,
      "B" => Colors.blue,
      "Y" => Colors.yellow,
      String() => null,
    };
    if (color == null || txt.length != 5) { //TODO: better error checking
      return Circle(color: Colors.black.withOpacity(.1), orig: "a1");
    } else {
      return Arrow(color: color,
          orig: txt.substring(1, 3).toLowerCase(),
          dest: txt.substring(3, 5).toLowerCase());
    }
  }

  ISet<Shape> getArrows(dynamic arrowList) {
    ISet<Shape> arrows = ISet();
    for (String arrowTxt in arrowList) {
      arrows = arrows.add(getArrow(arrowTxt));
    }
    return arrows;
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: Column(children: [
        Expanded(child: Container(color: Colors.black)),
        Container(
          color: Colors.black,
          width: screenWidth / 4,
          height: (screenWidth / 4) + 100,
          child: ListView(
            scrollDirection: Axis.vertical,
            children: [
              Text(headers["Black"].toString() ?? "",
                  overflow: TextOverflow.clip, style: textStyle),
              Board(
                size: screenWidth / 4,
                data: BoardData(
                    interactableSide: InteractableSide.none,
                    orientation: Side.white,
                    fen: history[ply]["fen"],
                    shapes: history[ply]["arrows"]),
              ),
              Text(headers["White"].toString() ?? "",
                  overflow: TextOverflow.clip, style: textStyle),
              Text(history[ply]["comment"],
                  overflow: TextOverflow.clip, style: textStyle),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      onPressed: () {
                        if (ply > 0) {
                          setState(() {
                            ply--;
                          });
                        }
                      },
                      icon: const Icon(Icons.arrow_left),
                      color: Colors.white),
                  IconButton(
                      onPressed: () {
                        if (ply < (history.length - 1)) {
                          setState(() {
                            ply++;
                          });
                        }
                      },
                      icon: const Icon(Icons.arrow_right),
                      color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}