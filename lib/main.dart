import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:mole_app/src/view/pages/game_page.dart';
import 'package:mole_app/src/model/mole_model.dart';
import 'package:mole_app/src/view/pages/mole_help.dart';
import 'package:mole_app/src/view/pages/mole_history.dart';
import 'package:mole_app/src/view/pages/mole_lobby.dart';
import 'package:mole_app/src/view/pages/mole_options.dart';
import 'package:mole_app/src/view/pages/mole_scores.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_app.dart';
import 'package:logging/logging.dart';
import 'package:zugclient/zug_chat.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_model.dart';
import 'package:zugclient/zug_option.dart';

//TODO: coordinates option, music/sound, help, option descriptions
//autologin for lichess, etc. (use prefs)

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ZugUtils.getIniDefaults("mole.ini").then((defaults) {
    ZugUtils.getPrefs().then((prefs) {
      String domain = defaults["domain"] ?? "molechess.com";
      int port = int.parse(defaults["port"] ?? "5555");
      String endPoint = defaults["endpoint"] ?? "molesrv";
      bool localServer = bool.parse(defaults["localServer"] ?? "true");
      log("Starting Mole Client, domain: $domain, port: $port, endpoint: $endPoint, localServer: $localServer");
      MoleModel client = MoleModel(domain, port, endPoint,localServer : localServer, javalinServer: true, prefs); //TODO: add default sound setting
      runApp(MoleApp(client,"MoleChess"));
    });
  });
}

class MoleApp extends ZugApp {
  static const double headerHeight = 36;

  MoleApp(super.client,super.appName,{
    super.logLevel = Level.INFO,
    super.colorSeed = Colors.brown, //Colors.greenAccent,
    super.key
  });

  String _getAppInfo(MoleModel client) {
    return "MoleClient Ver. ${client.packageInfo?.version ?? '?'}, Server Ver. ${client.serverVersion} ";
  }

  Color _getAppBarColor(BuildContext context, MoleModel client) {
    return switch(client.currentPage) {
      PageType.main => Colors.grey, //blueGrey,
      PageType.lobby => Colors.greenAccent, //Colors.brown,
      PageType.options => Colors.blue,
      PageType.none => Colors.white,
      PageType.splash => Colors.black,
    };
  }

  @override
  Widget createHomePage(ZugApp app) {
    return MoleHome(app: app);
  }

  @override
  Widget createMainPage(ZugModel model) {
    return CurrentGameWidget(model as MoleModel);
  }

  @override
  Widget createLobbyPage(ZugModel model) {
    if (model is MoleModel) {
      return switch(model.page) {
        MolePage.game => getLobbyPage(model),
        MolePage.lobby => getLobbyPage(model),
        MolePage.options => getLobbyPage(model),
        MolePage.help => MoleChessHelpPage(model),
        MolePage.top => MoleScorePage(model),
        MolePage.history => PlayerHistoryPage(model),
      };
    } throw UnknownValueTypeException(model);
  }

  Widget getLobbyPage(ZugModel model) => MoleLobbyPage(
    model,
    backgroundImage: null, //ZugUtils.getAssetImage("images/molefog1.png"),
    zugChat: ZugChat(model,
        width: 1000,
        areaName: "Game",
        serverName: "Lobby",
        borderColor: Colors.black,
        defScope: MessageScope.server),
  );

  @override
  Widget createOptionsPage(ZugModel model) {
    return MoleOptionsPage(model as MoleModel);
  }

  @override
  Widget createSplashPage(ZugModel model, {
    String landImgPath = "images/splash_land.png",
    String portImgPath = "images/splash_port.png",
    List<LoginType> allowedLoginTypes = LoginType.values}) {
    return super.createSplashPage(model,
        landImgPath: landImgPath,
        portImgPath: portImgPath,
        allowedLoginTypes: [LoginType.lichess,LoginType.none]);
  }

  @override
  AppBar createStatusBar(BuildContext context, ZugModel model, {Widget? txt, Color? color}) {
    String txt = model.isLoggedIn
        ? "${_getAppInfo(model as MoleModel)}, user: ${model.userName}, "
        "game: ${model.currentArea.id.isNotEmpty ? model.currentArea.id : 'none'}"
        : _getAppInfo(model as MoleModel);
    return AppBar(
        title: Text(txt),
        foregroundColor: _getAppBarColor(context, model), //blueGrey
        backgroundColor: model.currentPage == PageType.main ? Colors.black : Colors.black);
  }

  @override
  NavigationDestination getMainNavigationBarItem() {
    return NavigationDestination(
      icon: ImageIcon(ZugUtils.getAssetImage("images/mole_pieces/mole_knight_white.png"), color: Colors.white),
      label: 'Game',
    );
  }

}

class MoleHome extends ZugHome {
  const MoleHome({super.key, required super.app});
}
