import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'mole_model.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/lobby_page.dart';
import 'package:zugclient/zug_area.dart';
import 'package:zugclient/zug_fields.dart';
import "package:universal_html/html.dart" as html;
import 'package:zugclient/zug_model.dart';
import 'package:zugclient/zug_user.dart';
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
  List<CommandButtonData> getExtraCmdButtons(BuildContext context) {
    List<CommandButtonData> extras = super.getExtraCmdButtons(context);
    extras.add(CommandButtonData("Discord",Colors.purple,Icons.discord,gotoDiscord));
    return extras;
  }

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
                  return Color(0xFF2a3a4a) ; //Theme.of(context).colorScheme.inversePrimary;
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
                  MoleModel moleClient = model as MoleModel;
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
    MoleModel moleClient = model as MoleModel;
    MoleGame cg = moleClient.getCurrentGame();
    List<DataRow> rows = List<DataRow>.empty(growable: true);

    List<dynamic> players = [];
    for (dynamic p in cg.occupantMap.values) {
      players.add(p);
    }
    players.sort((a, b) => a[MoleFields.moleFieldSide].compareTo(b[MoleFields.moleFieldSide]));

    for (dynamic player in players) {
      UniqueName uName = UniqueName.fromData(player[fieldUser]);
      Color pColor = HexColor.fromHex(player[fieldChatColor]);

      rows.add(DataRow(cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Colored avatar circle
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pColor,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              // Player name with shadow
              Flexible(
                child: Text(
                  uName.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: "fixedsys",
                    fontSize: 15,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        DataCell(Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorMap[player["game_col"]],
            border: Border.all(color: Colors.white, width: 1),
          ),
        )),
        DataCell(Text(
          player["user"]["blitz"].toString(),
          style: const TextStyle(color: Colors.white),
        )),
        DataCell(Text(
          player["votename"] ?? "-",
          style: const TextStyle(color: Colors.white),
        )),
        DataCell(getIconButton(uName, player["kickable"] ? Icons.remove_circle_outline : Icons.not_interested, MoleClientMsg.kickoff, cg.id)),
      ]));
    }
    return rows;
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

  void gotoDiscord() {
    if (kIsWeb) {
      html.window.open("https://discord.gg/ak6d4wagnU", 'new tab');
    } else {
      ZugUtils.launch("https://discord.gg/ak6d4wagnU", isNewTab: true);
    }
  }

}