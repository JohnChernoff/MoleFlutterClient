import 'package:flutter/material.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/options_page.dart';
import 'package:zugclient/zug_client.dart';
import 'mole_client.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'mole_fields.dart';

class MoleOptionsPage extends StatefulWidget {
  final MoleClient client;

  const MoleOptionsPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _MoleOptionsPageState();

}

class _MoleOptionsPageState extends State<MoleOptionsPage> {

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = ZugUtils.getActualScreenHeight(context);
    final bool inGame = widget.client.currentArea.title != noGameTitle;

    return Column(
      children: [
        Container(
          color: Colors.greenAccent,
          width: screenWidth,
          height: inGame ? screenHeight/3 : screenHeight,
          child: Column(
            children: [
              const SizedBox(
                child: Text("General Options",style: TextStyle(fontSize: 24)),
              ),
              const Divider(
                color: Colors.black,
              ),
              Expanded(child: getGeneralOptions(screenWidth)),
            ],
          )

        ),
        !inGame ? const SizedBox.shrink() : Expanded(
          child: OptionsPage(widget.client, header: const SizedBox.shrink()),
        )
      ],
    );
  }

  Widget getGeneralOptions(double screenWidth) {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Piece Set:  "),
            DropdownButton<int>(
                value: widget.client.prefs?.getInt("piece_set") ?? defaultPieceSetIndex,
                items: List.generate(widget.client.customSets.length, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text(widget.client.customSets[index].name),
                  );
                }, growable: false),
                onChanged: (value) {
                  widget.client.prefs?.setInt("piece_set", value ?? defaultPieceSetIndex);
                  setState(() { /* piece set changed */ });
                }),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Board Style:  "),
            DropdownButton<String>(
                value: widget.client.prefs?.getString("board_colors") ?? defaultBoardColorScheme,
                items: List.generate(
                    BoardColor.values.length, (index) {
                  final schemeTxt =
                  BoardColor.values.elementAt(index).name;
                  return DropdownMenuItem(
                    value: schemeTxt,
                    child: Text(schemeTxt),
                  );
                }, growable: false),
                onChanged: (value) {
                  widget.client.prefs?.setString("board_colors", value ?? defaultBoardColorScheme);
                  setState(() { /* board colors changed */ });
                }),
          ],
        ),
        checkRow(widget.client,"Sound", "sound", ZugClient.defaultSound,onTrue: () => setState((){}),onFalse: () => widget.client.trackPlayer.stop()),
        checkRow(widget.client,"Streamer Mode", "streamer_mode",false,onFalse: () => setState((){})),
        //ZugUtils.checkRow(widget.client, this, "Movelist Hover Mode", "movelist_hover", MoleClient.defaultMoveListHover),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Notifications:  "),
            Row(
              children: List.generate(MoleFields.notifications.keys.length,
              (index) => Row(
                children: [
                  Text(MoleFields.notifications.keys.elementAt(index)),
                  Checkbox(
                      value:
                      MoleFields.notifications.values.elementAt(index),
                      onChanged: (b) => setState(() {
                        MoleFields.notifications[MoleFields.notifications.keys
                            .elementAt(index)] = b ?? false;
                        widget.client.updateNotifications();
                      })),
                ]),
            )),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Delete Oauth Token: "),
            IconButton(
              onPressed: () => widget.client.deleteToken(),
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      ],
    );
  }

  Row checkRow(ZugClient client, String caption, String prefProp, bool defaultValue, {Function? onTrue, Function? onFalse}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("$caption:"),
        Checkbox(
            value: client.prefs?.getBool(prefProp) ?? defaultValue,
            onChanged: (b) {
              client.prefs?.setBool(prefProp, b ?? defaultValue);
              ZugClient.log.info("Setting $caption: $b");
              if ((b ?? false)) {
                if (onTrue != null) onTrue();
              } else {
                if (onFalse != null) {
                  onFalse();
                }
              }
            }),
      ],
    );
  }

}

