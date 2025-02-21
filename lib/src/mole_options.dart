import 'package:flutter/material.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/options_page.dart';
import 'package:zugclient/zug_client.dart';
import 'mole_client.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
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
    final bool inGame = widget.client.currentArea.title != noGameTitle;

    return ColoredBox(color: Colors.blue, child: DefaultTabController(length: 2, child: Column(
      children: [
        const TabBar(indicatorColor: Colors.white, labelColor: Colors.white, tabs: [
          Text("General Options",style: TextStyle(fontSize: 24)),
          Text("Game Options",style: TextStyle(fontSize: 24)),
        ]),
        Expanded(child: TabBarView(children: [
          getGeneralOptions(),
          OptionsPage(widget.client, scope: OptionScope.area, customHeader: const SizedBox.shrink())
        ]))
      ],
    )));
  }

  Widget getGeneralOptions() {
    return Column(
      children: [
        Expanded(child: OptionsPage(
            widget.client,scope: OptionScope.general,
            //optionsBackgroundColor: Colors.orange, //const Color(0xFF88AA55),
            //optionsDropdownCBkgCol: Colors.cyan,
            //optionsTextColor: Colors.black,
            customHeader: const SizedBox.shrink())),
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

}

