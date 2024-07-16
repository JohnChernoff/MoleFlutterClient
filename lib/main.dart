import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:mole_app/src/main_page.dart';
import 'package:mole_app/src/mole_client.dart';
import 'package:mole_app/src/mole_lobby.dart';
import 'package:mole_app/src/mole_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zugclient/zug_app.dart';
import 'package:logging/logging.dart';
import 'package:zugclient/zug_client.dart';
import 'package:zugclient/zug_utils.dart';

//TODO: coordinates option
//autologin for lichess, etc. (use prefs)
//obvious game link button

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ZugUtils.getIniDefaults("mole.ini").then((defaults) {
    SharedPreferences.getInstance().then((prefs) {
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
    super.key
  });

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
    return MoleLobbyPage(client,defaultColorScheme.background,defaultColorScheme.onBackground);
  }

  @override
  Widget createOptionsPage(client) {
    return MoleOptionsPage(client);
  }

}

class MoleHome extends ZugHome {
  const MoleHome({super.key, required super.app});

  @override
  Color getAppBarColor(BuildContext context, ZugClient client) {
    return switch(client.selectedPage) {
      PageType.main => Colors.black,
      PageType.lobby => Colors.brown,
      PageType.options => Colors.orange,
      PageType.none => Colors.white,
    };
  }

  @override
  Text getAppBarText(ZugClient client, {String? text, Color textColor = Colors.black}) {
    return super.getAppBarText(client,
        text: client.isLoggedIn ? "${getAppInfo(client as MoleClient)}, user: ${client.user}, "
            "game: ${client.currentArea.title.isNotEmpty ? client.currentArea.title : 'none'}"
            : getAppInfo(client as MoleClient),
        textColor: client.selectedPage == PageType.main ? Colors.grey : Colors.black);
  }

  @override
  BottomNavigationBarItem getMainNavigationBarItem() {
    return BottomNavigationBarItem(
      icon: ImageIcon(ZugUtils.getAssetImage("images/mole_pieces/mole_knight_white.png")),
      label: 'Game',
    );
  }

  String getAppInfo(MoleClient client) {
    return "MoleClient Ver. ${client.packageInfo?.version ?? '?'}, Server Ver. ${client.serverVersion} ";
  }

}
