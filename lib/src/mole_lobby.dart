import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mole_app/src/mole_client.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/lobby_page.dart';
import 'package:zugclient/zug_area.dart';
import 'package:zugclient/zug_fields.dart';
import "package:universal_html/html.dart" as html;
import 'package:zugclient/zug_model.dart';
import 'mole_fields.dart';

class MoleLobbyPage extends LobbyPage {

  final Map<int,Color> colorMap = {
    -1 : Colors.grey,
    0 : Colors.black,
    1: Colors.white
  };

  MoleLobbyPage(super.model, {
    super.areaName ="Mole Game",
    super.bkgCol = Colors.black,
    super.buttonsBkgCol = Colors.black,
    super.backgroundImage,
    super.zugChat,
    super.commandAreaWidth = 255,
    super.commandAreaHeight = 128,
    super.key});

  @override
  Widget selectedArea(BuildContext context, {Color? bkgCol, Color? txtCol, Iterable<dynamic>? occupants}) {
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
                dataRowColor: WidgetStateProperty.resolveWith((Set states) {
                  return Colors.grey; //Theme.of(context).colorScheme.inversePrimary;
                }),
                headingRowColor:
                    WidgetStateProperty.resolveWith((Set states) {
                  return Colors.white12; //Theme.of(context).colorScheme.onSecondary;
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
                  MoleClient moleClient = model as MoleClient;
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
  Widget getAreaItem(String? title,context) {  //print("Title: $title");
    if (title == null || title == ZugModel.noAreaTitle) return super.getAreaItem(title,context);
    MoleGame game = (model.areas[title] as MoleGame);
    return Row(
      children: [
        super.getAreaItem(title,context),
        super.getAreaItem(game.getPhaseString(),context),
      ],
    );
  }

  @override
  int compareAreas(Area? a, Area? b) { //print("Area a: $a"); print("Area b: $a");
    if (a == null || b == null) return 0;
    if (a is MoleGame && b is MoleGame) { //print(a.jsonData);
      Iterable<dynamic> players1 = a.occupantMap.values;
      int p1 = players1.length >= 6 ? 0 : players1.length;
      Iterable<dynamic> players2 = b.occupantMap.values;
      int p2 = players2.length >= 6 ? 0 : players2.length;
      int c = -(p1.compareTo(p2));
      if (c == 0) {
        return super.compareAreas(a,b);
      } else {
        return c;
      }
    }
    return 0;
  }

  List<DataColumn> _gameColumns({txtColor = Colors.white}) {
    return [
      DataColumn(label: Text('Player',style: TextStyle(color: txtColor))),
      DataColumn(label: Text('Color',style: TextStyle(color: txtColor))),
      DataColumn(label: Text('Rating',style: TextStyle(color: txtColor))),
      DataColumn(label: Text('Accusing',style: TextStyle(color: txtColor))),
      DataColumn(label: Text('Kick',style: TextStyle(color: txtColor))),
    ];
  }

  List<DataRow> _gameRows() {
    MoleClient moleClient = model as MoleClient;
    MoleGame cg = moleClient.getCurrentGame();
    List<DataRow> rows = List<DataRow>.empty(growable: true);
    //if (!cg.exists) return rows; //print(cg.title); print(cg.occupantMap.values);
    List<dynamic> players = [];
    for (dynamic p in cg.occupantMap.values) {
      players.add(p); //print("Adding:  ${p.toString()}");
    }
    players.sort((a, b) => a[MoleFields.moleFieldSide].compareTo(b[MoleFields.moleFieldSide]));
    for (dynamic player in players) { //print("Player: $player");
      UniqueName uName = UniqueName.fromData(player[fieldUser]);
      Color pColor = HexColor.fromHex(player[fieldChatColor]);
      rows.add(DataRow(cells: [
        DataCell(
            FittedBox(child: //DecoratedBox(decoration: getPlayerDecoration(), child:
            //Text(uName.name,textScaler: const TextScaler.linear(1.5), style : TextStyle(backgroundColor: Colors.black, color: pColor))))),
            Stack(children: [
                Text(uName.name,textScaler: const TextScaler.linear(1.5), style : TextStyle(fontFamily: "fixedsys", foreground: Paint(
                )..style = PaintingStyle.stroke..strokeWidth = 4..color = Colors.black)),
                Text(uName.name,textScaler: const TextScaler.linear(1.5), style : TextStyle(fontFamily: "fixedsys",color: pColor))
        ]))),
        DataCell(Container(
            color: colorMap[player["game_col"]],
            margin: const EdgeInsets.all(8),
        )),
        DataCell(Text(player["user"]["blitz"].toString())),
        DataCell(FittedBox(child: Text(player["votename"] ?? "-"))),
        //DataCell(getIconButton(uName, Icons.where_to_vote,MoleClientMsg.voteoff,cg.title)),
        DataCell(getIconButton(uName, player["kickable"] ? Icons.remove_circle_outline : Icons.not_interested,MoleClientMsg.kickoff,cg.id)),
      ]));
    }
    return rows;
  }

  Decoration getPlayerDecoration() {
    return BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent,
            offset: Offset(
              5.0,
              5.0,
            ),
            blurRadius: 10.0,
            spreadRadius: 2.0,
          ), //BoxShadow
          BoxShadow(
            color: Colors.white,
            offset: Offset(0.0, 0.0),
            blurRadius: 0.0,
            spreadRadius: 0.0,
          ), //BoxShadow

        ]
    );
  }

  IconButton getIconButton(UniqueName targetUniqueName, IconData iconData, Enum action, String title) {
    return IconButton(
        onPressed: () {
          model.areaCmd(action, data: { "player" : targetUniqueName.toJSON()}); //TODO: deal with authSource
        },
        icon: Icon(
          iconData,
        ));
  }

  //TODO: add this in
  Widget getSocialMediaButtons() {
    return ElevatedButton(
        style: getButtonStyle(Colors.purple),
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