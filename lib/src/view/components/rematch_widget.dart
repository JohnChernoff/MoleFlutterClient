import 'package:flutter/material.dart';
import 'package:mole_app/src/model/mole_game.dart';
import 'package:zugclient/zug_user.dart';

class RematchWidget extends StatefulWidget {
  final double size;
  final MoleGame game;
  final Widget board;
  final VoidCallback onRematching;
  final VoidCallback onRematch;
  final UniqueName? userName;

  const RematchWidget(this.game, { required this.userName,
    required this.board, required this.size, required this.onRematching, required this.onRematch,
    super.key});

  @override
  State<StatefulWidget> createState() => _RematchWidgetState();
}

class _RematchWidgetState extends State<RematchWidget> {
  List<UniqueName> rematchingPlayers = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isCreator = widget.game.occupantMap[widget.userName]?["creator"];
    bool isRematching = widget.game.occupantMap[widget.userName]?["rematching"];
    rematchingPlayers = widget.game.occupantMap.keys
        .where((k) => widget.game.occupantMap[k]!["rematching"] == true).toList();
    return Container(width:  widget.size, height: widget.size, color: Colors.black,
        child: Row(children: [
          Column(children: [
            widget.board,
            Expanded(child: Column(children: [ Text("Game Over!"), Text(widget.game.getResultString())])),
            if (isCreator) ElevatedButton(onPressed: widget.onRematch, child: Text("Start Rematch")),
            ElevatedButton(onPressed: widget.onRematching, child: isRematching ? Text("Leave Rematch") : Text("Join Rematch"))
          ]),
          Expanded(child: Container(
            color: Colors.brown,
            child: Column(children: List.generate(rematchingPlayers.length, (i) =>
              rematchingPlayers.elementAt(i).toWidget(color: Colors.white, bkgColor: Colors.black)
              ))
            )
          )
        ])
    );
  }

}