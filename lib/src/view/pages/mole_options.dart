import 'package:flutter/material.dart';
import 'package:zugclient/options_page.dart';
import '../../model/mole_model.dart';
import '../../model/mole_fields.dart';

class MoleOptionsPage extends StatefulWidget {
  final MoleModel client;

  const MoleOptionsPage(this.client, {super.key});

  @override
  State<StatefulWidget> createState() => _MoleOptionsPageState();

}

class _MoleOptionsPageState extends State<MoleOptionsPage> {

  @override
  Widget build(BuildContext context) {
    final bool inGame = widget.client.currentArea.id != noGameTitle;

    return ColoredBox(color: Colors.blue, child: DefaultTabController(length: inGame ? 2 : 1, child: Column(
      children: [
        TabBar(indicatorColor: Colors.white, labelColor: Colors.white, tabs: [
          if (inGame) const Text("Game Options",style: TextStyle(fontSize: 24)),
          const Text("General Options",style: TextStyle(fontSize: 24)),
        ]),
        Expanded(child: TabBarView(children: [
          if (inGame) OptionsPage(widget.client, scope: OptionScope.area, customHeader: const SizedBox.shrink()),
          getGeneralOptions(),
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

