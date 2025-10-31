import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../model/mole_model.dart';
import '../../model/mole_fields.dart';

List<Widget> getBoardHeaderButtons(MoleModel model, double width, {iconColor = Colors.grey}) {
  bool shortWidth = width < 720;
  return [
    ElevatedButton(
        style: getCommandButtonStyle(),
        onPressed: () {
          model.areaCmd(MoleClientMsg.role);
        },
        child: Row(
          children: [
            const Icon(Icons.info),
            shortWidth ? const SizedBox.shrink() : const Text(" Role"),
          ],
        )),
    ElevatedButton(
        style: getCommandButtonStyle(),
        onPressed: () {
          model.flipBoard();
        },
        child: Row(
          children: [
            const Icon(CupertinoIcons.arrow_up_left_arrow_down_right),
            shortWidth ? const SizedBox.shrink() : const Text(" Flip"),
          ],
        )),
    ElevatedButton(
      style: getCommandButtonStyle(),
      onPressed: () {
        model.areaCmd(MoleClientMsg.draw);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.equal_circle),
          shortWidth ? const SizedBox.shrink() : const Text(" Draw"),
        ],
      ),
    ),
    ElevatedButton(
      style: getCommandButtonStyle(),
      onPressed: () {
        model.areaCmd(MoleClientMsg.resign);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag),
          shortWidth ? const SizedBox.shrink() : const Text(" Resign"),
        ],
      ),
    ),
    ElevatedButton(
      style: getCommandButtonStyle(),
      onPressed: () {
        model.areaCmd(MoleClientMsg.veto, data: {"confirm": true});
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cancel),
          shortWidth ? const SizedBox.shrink() : const Text(" Veto"),
        ],
      ),
    ),
    ElevatedButton(
      style: getCommandButtonStyle(),
      onPressed: () {
        model.areaCmd(MoleClientMsg.inspect);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.search), //Icons.find_replace),
          shortWidth ? const SizedBox.shrink() : const Text(" Inspect"),
        ],
      ),
    ),
    ElevatedButton(
      style: getCommandButtonStyle(),
      onPressed: () {
        model.areaCmd(MoleClientMsg.pgn);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.download), //Icons.find_replace),
          shortWidth ? const SizedBox.shrink() : const Text(" PGN"),
        ],
      ),
    ),
  ];
}

ButtonStyle getCommandButtonStyle() {
  return ButtonStyle(
      backgroundColor: WidgetStateColor.resolveWith((states) => Colors.black),
      foregroundColor: WidgetStateColor.resolveWith((states) => Colors.grey)
  );
}
