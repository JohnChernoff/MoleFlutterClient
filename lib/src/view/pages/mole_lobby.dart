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
    super.useSelectedWidget = false,
    super.startButt = false,
    super.partButt = false,
    super.joinButt = false,
    super.key});

  bool inGame(MoleGame game) => game.containsOccupant(model.userName);
  bool isCreator(MoleGame game) => model.userName == game.creator;
  bool isSelected(MoleGame game) => model.currentArea == game;

  @override
  bool get seekButt => false;

  @override
  List<CommandButtonData> getExtraCmdButtons(BuildContext context) {
    MoleModel moleModel = model as MoleModel;
    List<CommandButtonData> extras = super.getExtraCmdButtons(context);
    extras.add(CommandButtonData("Help",Colors.blue,Icons.help,() => moleModel.switchLobbyPage(MolePage.help)));
    extras.add(CommandButtonData("Discord",Colors.purple,Icons.discord,gotoDiscord));
    //extras.add(CommandButtonData("Top",Colors.cyan,Icons.star,() => moleModel.getTop(10)));
    //extras.add(CommandButtonData("History",Colors.brown,Icons.hourglass_bottom,() => moleModel.getPlayerHistory(moleModel.userName)));
    //extras.add(CommandButtonData("Events",Colors.green,Icons.event,() => moleModel.getEvents()));
    return extras;
  }

  //TODO: make collapsable
  @override
  Widget selectorWidget(BuildContext context, {required Function(String title) onSelected}) { //print("Titles: ${ model.areas.keys}");
    for (String key in model.areas.keys) {
      //MoleGame game = model.areas[key]! as MoleGame; print("$key: ${game.status} , ${game.gameState} , ${game.phase}");
    }
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
          return InkWell( //only happens if you don't click stuff within the gameItem
              onTap: () => model.currentArea == model.areas[title] ? onSelected(noGameTitle) : onSelected(title),
              onDoubleTap: () {
                onSelected(title);
                model.gotoPage(PageType.main);
              },
              child: getGameItem(title,model.areas[title] as MoleGame, onSelected))
          ;
        })
    ));
  }

  Widget getGameItem(String title, MoleGame game, Function(String title) onSelected) {
    List<UniqueName> nameList = game.occupantMap.keys.toList();
    nameList.sort((a,b) => game.occupantMap[a]['game_col'] - game.occupantMap[b]['game_col']);

    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Container(
      decoration: isSelected(game) ? BoxDecoration(
          border: Border.all(color: Colors.white, width: 2)
      ) : null,
      child: Row(children: [
        Text("$title : "),
        Row(children: List.generate(nameList.length, (i) {
          final uName = nameList.elementAt(i);
          final data = game.occupantMap[uName];
          Color? color = colorMap[data['game_col']];
          return uName.toWidget(color: Colors.black, bkgColor: color == Colors.white
              ? Colors.brown
              : color == Colors.black ? Colors.cyanAccent : Colors.grey);
        })),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onOpened: () => onSelected(title),
          onSelected: (value) {
            switch (value) {
              case 'join':
                model.joinArea(title);
                break;
              case 'settings':
                model.gotoPage(PageType.options);
                break;
              case 'leave':
                getPartButton().callback();
                break;
              case 'link':
                (model as MoleModel).copyGameLink((model as MoleModel).getCurrentGame());
                break;
              case 'start':
                getStartButton().callback();
                break;
            }
          },
          itemBuilder: (context) => [
            if (!inGame(game)) const PopupMenuItem(
                value: 'join',  child: ListTile(leading: Icon(Icons.login),    title: Text('Join'))),
            const PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings), title: Text('Settings'))),
            if (inGame(game)) const PopupMenuItem(value: 'leave', child: ListTile(leading: Icon(Icons.backspace_outlined), title: Text('Leave'))),
            const PopupMenuItem(value: 'link',  child: ListTile(leading: Icon(Icons.link),     title: Text('Copy Link'))),
            if (isCreator(game)) const PopupMenuItem(value: 'start', child: ListTile(leading: Icon(Icons.start),    title: Text('Start'))),
          ],
        ),
      ]),
    ));
  }

  void selectGame(String title,Function(String title) onSelected) {
    if (model.currentArea.id != title) onSelected;
  }

  void gotoDiscord() {
    if (kIsWeb) {
      html.window.open("https://discord.gg/ak6d4wagnU", 'new tab');
    } else {
      ZugUtils.launch("https://discord.gg/ak6d4wagnU", isNewTab: true);
    }
  }

}