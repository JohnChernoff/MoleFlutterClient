import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zugclient/zug_app.dart';
import '../../model/mole_model.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/lobby_page.dart';
import "package:universal_html/html.dart" as html;
import 'package:zugclient/zug_user.dart';
import '../../model/mole_fields.dart';
import 'package:mole_app/src/model/mole_game.dart';

class MoleLobbyPage extends LobbyPage {
  final bool hideSelectedArea = true;
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
  bool get seekButt => false;

  @override
  List<CommandButtonData> getExtraCmdButtons(BuildContext context) {
    MoleModel moleModel = model as MoleModel;
    List<CommandButtonData> extras = super.getExtraCmdButtons(context);
    extras.add(CommandButtonData("Help",Colors.blue,Icons.help,() => moleModel.gotoMolePage(MolePage.help)));
    extras.add(CommandButtonData("Discord",Colors.purple,Icons.discord,gotoDiscord));
    extras.add(CommandButtonData("Top",Colors.cyan,Icons.star,() => moleModel.getTop(10)));
    extras.add(CommandButtonData("History",Colors.brown,Icons.hourglass_bottom,() => moleModel.getPlayerHistory(moleModel.userName)));
    extras.add(CommandButtonData("Events",Colors.green,Icons.event,() => moleModel.getEvents()));
    return extras;
  }

  @override
  Widget selectorWidget(BuildContext context, {required Function(String title) onSelected}) {
    Map<MoleGameStatus,List<String>> statusMap = {};
    for (MoleGameStatus status in MoleGameStatus.values) {
      statusMap[status] = model.areas.keys.where((k) => (model.areas[k]! as MoleGame).status == status).toList();
    }
    return Expanded(child: Column(
      children: [
        Center(child: Text("Click to select a game below (double click to go the board)")),
        Divider(),
        Text("Forming games"),
        getGameList(statusMap[MoleGameStatus.pregame] ?? [],onSelected),
        Text("Running games"),
        getGameList(statusMap[MoleGameStatus.playing] ?? [],onSelected),
        Text("Finished games"),
        getGameList(statusMap[MoleGameStatus.finished] ?? [],onSelected),
      ],
    ));
  }

  Widget getGameList(List<String> titles,Function(String title) onSelected) {
    return Expanded(child: ListView(scrollDirection: Axis.vertical,
        children: List.generate(titles.length, (i) {
          String title = titles.elementAt(i);
          return InkWell(
              onTap: () => model.currentArea == model.areas[title] ? onSelected(noGameTitle) : onSelected(title),
              onDoubleTap: () {
                onSelected(title);
                model.goToPage(PageType.main);
              },
              child: getGameItem(title,model.areas[title] as MoleGame))
          ;
        })
    ));
  }

  Widget getGameItem(String title, MoleGame game) { //print("Game Data: ${game.upData}"); print("$title Phase: ${game.status}");
    List<UniqueName> nameList = game.occupantMap.keys.toList();
    nameList.sort((a,b) => game.occupantMap[a]['game_col'] - game.occupantMap[b]['game_col']);
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Container(
        decoration: model.currentArea == game ? BoxDecoration(
          border: Border.all(color: Colors.white, width: 2)
        ) : null,
        child: Row(children: [
          IconButton(
            onPressed: () {
              MoleModel moleClient = model as MoleModel;
              moleClient.copyGameLink(moleClient.getCurrentGame());
            }, //icon: const Icon(Icons.copy),
            icon: const Icon(Icons.link), //Text("Link", style: TextStyle(color: Colors.blueGrey)),
          ),
          Text("$title : "),
          Row(children: List.generate(nameList.length, (i) {
            final uName = nameList.elementAt(i);
            final data = game.occupantMap[uName]; //print("User data: $data");
            Color? color = colorMap[data['game_col']];
            return uName.toWidget(color: Colors.black, bkgColor: color == Colors.white
                ? Colors.brown
                : color == Colors.black ? Colors.cyanAccent : Colors.grey);
          })),
          if (model.currentArea == model.areas[title]) IconButton(
            onPressed: () {
              model.goToPage(PageType.options);
            }, //icon: const Icon(Icons.copy),
            icon: const Icon(Icons.settings), //Text("Link", style: TextStyle(color: Colors.blueGrey)),
          ),
    ])));
  }

  @override
  Widget selectedArea(BuildContext context, {Color? bkgCol, Color? txtCol, Iterable<dynamic>? occupants}) => SizedBox.shrink();

  void gotoDiscord() {
    if (kIsWeb) {
      html.window.open("https://discord.gg/ak6d4wagnU", 'new tab');
    } else {
      ZugUtils.launch("https://discord.gg/ak6d4wagnU", isNewTab: true);
    }
  }

}