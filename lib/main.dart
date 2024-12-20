import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:mole_app/src/main_page.dart';
import 'package:mole_app/src/mole_client.dart';
import 'package:mole_app/src/mole_lobby.dart';
import 'package:mole_app/src/mole_options.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_app.dart';
import 'package:logging/logging.dart';
import 'package:zugclient/zug_chat.dart';
import 'package:zugclient/zug_client.dart';
import 'package:zugclient/zug_fields.dart';

//TODO: coordinates option
//autologin for lichess, etc. (use prefs)
//obvious game link button

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ZugUtils.getIniDefaults("mole.ini").then((defaults) {
    ZugUtils.getPrefs().then((prefs) {
      String domain = defaults["domain"] ?? "molechess.com";
      int port = int.parse(defaults["port"] ?? "5555");
      String endPoint = defaults["endpoint"] ?? "server";
      bool localServer = bool.parse(defaults["localServer"] ?? "true");
      log("Starting Mole Client, domain: $domain, port: $port, endpoint: $endPoint, localServer: $localServer");
      MoleClient client = MoleClient(domain, port, endPoint,localServer : localServer,prefs); //TODO: add default sound setting
      runApp(MoleApp(client,"MoleChess"));
    });
  });
}

class MoleApp extends ZugApp {

  MoleApp(super.client,super.appName,{
    super.splashLandscapeImgPath = "images/splash_land.png", //TODO: place in mole.ini
    super.logLevel = Level.INFO,
    //super.colorSeed = Colors.greenAccent,
    super.colorSeed = Colors.brown,
    super.key
  });

  String _getAppInfo(MoleClient client) {
    return "MoleClient Ver. ${client.packageInfo?.version ?? '?'}, Server Ver. ${client.serverVersion} ";
  }

  Color _getAppBarColor(BuildContext context, ZugClient client) {
    return switch(client.selectedPage) {
      PageType.main => Colors.black,
      PageType.lobby => Colors.greenAccent, //Colors.brown,
      PageType.options => Colors.orange,
      PageType.none => Colors.white,
    };
  }

  @override
  Widget createHomePage(ZugApp app) {
    return MoleHome(app: app);
  }

  @override
  Widget createMainPage(client) {
    return MainMolePage(client);
  }

  @override
  Widget createLobbyPage(client) {
    return MoleLobbyPage(
      client,
      backgroundImage: ZugUtils.getAssetImage("images/molefog.png"),
      helpPage: "https://molechess.com/help/index.html",
      chatArea: ZugChat(client,
          widthFactor: .33,
          serverName: "Lobby",
          defScope: MessageScope.server),
    );
  }

  @override
  Widget createOptionsPage(client) {
    return MoleOptionsPage(client);
  }

  @override
  AppBar createAppBar(BuildContext context, ZugClient client, {Widget? txt, Color? color}) {
    String txt = client.isLoggedIn
        ? "${_getAppInfo(client as MoleClient)}, user: ${client.userName}, "
        "game: ${client.currentArea.title.isNotEmpty ? client.currentArea.title : 'none'}"
        : _getAppInfo(client as MoleClient);
    return AppBar(
        title: Text(txt),
        foregroundColor: _getAppBarColor(context, client),
        backgroundColor: client.selectedPage == PageType.main ? Colors.grey : Colors.black);
  }

  @override
  BottomNavigationBarItem getMainNavigationBarItem() {
    return BottomNavigationBarItem(
      icon: ImageIcon(ZugUtils.getAssetImage("images/mole_pieces/mole_knight_white.png")),
      label: 'Game',
    );
  }

}

class MoleHome extends ZugHome {
  const MoleHome({super.key, required super.app});
}
