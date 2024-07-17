import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mole_app/src/mole_client.dart';
import 'package:zugclient/lobby_page.dart';
import 'package:zugclient/zug_client.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_utils.dart';
import "package:universal_html/html.dart" as html;
import 'mole_fields.dart';

class MoleLobbyPage extends LobbyPage {

  final Map<int,Color> colorMap = {
    -1 : Colors.grey,
    0 : Colors.black,
    1: Colors.white
  };

  MoleLobbyPage(super.client, {
    super.areaName ="Mole Game",
    super.backgroundImage,
    super.backgroundColor,
    super.foregroundColor,
    super.helpPage,
    super.chatArea,
    super.key});

  @override
  Widget selectedArea(BuildContext context) {
    List<DataRow> rows = _gameRows();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
                dividerThickness: 2,
                columnSpacing: 16,
                dataRowColor: MaterialStateProperty.resolveWith((Set states) {
                  return Colors.grey; //Theme.of(context).colorScheme.inversePrimary;
                }),
                headingRowColor:
                    MaterialStateProperty.resolveWith((Set states) {
                  return Colors.green; //Theme.of(context).colorScheme.onSecondary;
                }),
                //headingTextStyle: const TextStyle(color: Colors.yellowAccent),
                columns: _gameColumns(),
                rows: rows),
          ),
        ),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  MoleClient moleClient = client as MoleClient;
                  moleClient.copyGameLink(moleClient.getCurrentGame());
                },
                //icon: const Icon(Icons.copy),
                child: const Text("Copy Game Link", style: TextStyle(color: Colors.blueGrey)),
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget getAreaItem(String? title) {  //print("Title: $title");
    if (title == null || title == ZugClient.noAreaTitle) return super.getAreaItem(title);
    MoleGame game = (client.areas[title] as MoleGame);
    return Row(
      children: [
        super.getAreaItem(title),
        super.getAreaItem(getGamePhase(game.listData["phase"])),
      ],
    );
  }

  @override
  int compareGames(Area? a, Area? b) { //print("Area a: $a"); print("Area b: $a");
    if (a == null || b == null) return 0;
    if (a is MoleGame && b is MoleGame) { //print(a.jsonData);
      Iterable<dynamic> players1 = a.occupantMap.values;
      int p1 = players1.length >= 6 ? 0 : players1.length;
      Iterable<dynamic> players2 = b.occupantMap.values;
      int p2 = players2.length >= 6 ? 0 : players2.length;
      int c = -(p1.compareTo(p2));
      if (c == 0) {
        return super.compareGames(a,b);
      } else {
        return c;
      }
    }
    return 0;
  }

  String getGamePhase(String? phase) {
    if (phase == null) return " (?) ";
    if (phase.toLowerCase() == GamePhase.pregame.name) return " (open) ";
    if (phase.toLowerCase() == GamePhase.postgame.name) return " (closing) ";
    return " (running) ";
  }

  List<DataColumn> _gameColumns() {
    return [
      const DataColumn(label: Text('Player')),
      const DataColumn(label: Text('Color')),
      const DataColumn(label: Text('Rating')),
      const DataColumn(label: Text('Vote')),
      const DataColumn(label: Text('Accuse')),
      const DataColumn(label: Text('Kick')),
    ];
  }

  List<DataRow> _gameRows() {
    MoleClient moleClient = client as MoleClient;
    MoleGame cg = moleClient.getCurrentGame();
    List<DataRow> rows = List<DataRow>.empty(growable: true);
    if (!cg.exists) return rows; //print(cg.title); print(cg.occupantMap.values);
    List<dynamic> players = [];
    for (dynamic p in cg.occupantMap.values) {
      players.add(p); //print("Adding:  ${p.toString()}");
    }
    players.sort((a, b) => a[MoleFields.moleFieldSide].compareTo(b[MoleFields.moleFieldSide]));
    for (dynamic player in players) { //print("Player: $player");
      //dynamic uniqueName = { fieldName : player[fieldUser][fieldName], fieldAuthSource : player[fieldUser][fieldAuthSource]};
      String uName = ZugUtils.getOccupantName(player);
      Color pColor = HexColor.fromHex(player[fieldChatColor]);
      rows.add(DataRow(cells: [
        DataCell(Text(uName,textScaleFactor: 1.5, style : TextStyle(backgroundColor: Colors.black, color: pColor))),
        DataCell(Container(
            color: colorMap[player["game_col"]],
            margin: const EdgeInsets.all(8),
        )),
        DataCell(Text(player["user"]["blitz"].toString())),
        DataCell(Text(player["votename"])),
        DataCell(getIconButton(uName, Icons.where_to_vote,MoleClientMsg.voteoff,cg.title)),
        DataCell(getIconButton(uName, player["kickable"] ? Icons.remove_circle_outline : Icons.not_interested,MoleClientMsg.kickoff,cg.title)),
      ]));
    }
    return rows;
  }

  IconButton getIconButton(dynamic targetUniqueName, IconData iconData, Enum action, String title) {
    return IconButton(
        onPressed: () {
          client.send(action, data: { "player" : targetUniqueName, fieldTitle : title}); //TODO: deal with authSource
        },
        icon: Icon(
          iconData,
        ));
  }

  @override
  Widget getSocialMediaButtons() {
    return ElevatedButton(
        style: getButtonStyle(Colors.purple, Colors.purpleAccent),
        onPressed: ()  {
          if (kIsWeb) {
            html.window.open("https://discord.gg/ak6d4wagnU", 'new tab');
          } else {
            ZugUtils.launch("https://discord.gg/ak6d4wagnU", isNewTab: true);
          }
        },
        child: Text("Discord",style: getButtonTextStyle()));
  }

}