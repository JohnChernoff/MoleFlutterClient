import 'dart:math';
import 'package:flutter/material.dart';
import 'package:zugclient/zug_client.dart';
import 'package:zugclient/zug_utils.dart';
import 'mole_client.dart';
import 'mole_fields.dart';

class TimeSelectDialogOptions extends StatelessWidget {
  const TimeSelectDialogOptions({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = ZugUtils.getActualScreenHeight(context);

    return Container(
        color: Colors.black,
        width: screenWidth / 2,
        height: screenHeight / 2,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Text("Select a time control: ", style: TextStyle(color: Colors.white)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            getTimeOption(15, 100, context),
            getTimeOption(30, 100, context),
            getTimeOption(45, 100, context),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            getTimeOption(60, 100, context),
            getTimeOption(90, 100, context),
            getTimeOption(120, 100, context),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            getTimeOption(180, 100, context),
            getTimeOption(300, 100, context),
            getTimeOption(600, 100, context),
          ],
        ),
      ],
    ));
  }

  Widget getTimeOption(int t, double size, BuildContext context) {
    return TextButton(
        onPressed: () => Navigator.pop(context, t),
        child: Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border.all(
                color: Colors.white,
                width: 2
              )
            ),
            width: size,
            height: size,
            child: Center(
                child: Text(
                    formatTimeOption(t), //TODO: convert to minutes, etc.
                    style: const TextStyle(color: Colors.white, fontSize: 24)
                )
            )
        )
    );
  }

  String formatTimeOption(int t) {
    int minutes = (t / 60).floor();
    int seconds = t - (minutes * 60);
    return minutes > 0 ?
    (seconds > 0 ? "$minutes:$seconds" : "$minutes min") : "$seconds sec";
  }

}

class PlayerOptionsDialog extends StatelessWidget {
  final UniqueName playerName;
  final MoleGame game;
  final Color txtColor;
  final Color bkgColor;

  const PlayerOptionsDialog(this.playerName,this.game, {
    this.txtColor = Colors.deepPurple,
    this.bkgColor = Colors.white,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bkgColor,
      padding: const EdgeInsets.all(8),
      child: FittedBox(
        child: Column(
          children: [
            getText("Select an action for player: ${playerName.name}"),
            Center(child: getActionList(context)),
          ],
        )
    ));
  }

  Widget getActionList(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context, getAction(PlayerAction.accuse)),
          child: getText("Accuse"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, getAction(PlayerAction.kick)),
          child: getText("Kick"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, getAction(PlayerAction.ban)),
          child: getText("Ban"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, getAction(PlayerAction.finger)),
          child: getText("Info"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, getAction(PlayerAction.whisper)),
          child: getText("Whisper"),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context, getAction(PlayerAction.cancel)),
          icon: const Icon(Icons.cancel),
        )
      ],
    );
  }

  dynamic getAction(PlayerAction action) {
    return {
      "action" : action,
      "gameTitle" : game.title,
      "playerName" : playerName
    };
  }

  Text getText(String msg) {
    return Text(msg,style: TextStyle(
      color: txtColor,
      fontWeight: FontWeight.bold
    ));
  }

}

class MoleDance extends StatefulWidget {
  final double? size;
  final double? widthPercent, heightPercent;
  final Image moleImg;
  final int animationSpeed;
  final String caption;

  const MoleDance(this.caption,this.moleImg,{this.size,this.widthPercent,this.heightPercent,this.animationSpeed = 2000, super.key});

  @override
  State<StatefulWidget> createState() => MoleDanceState();

}

class MoleDanceState extends State<MoleDance> {

  Point location = const Point(0,0);
  double rotZ = 0;
  Matrix4 matrix = Matrix4.identity();
  double moleWidth = 100, moleHeight = 50;
  bool initialFrame = true;

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = ZugUtils.getActualScreenHeight(context);

    double size = widget.size ?? min(screenWidth,screenHeight);
    double widgetWidth = size;
    double widgetHeight = size;

    if (widget.widthPercent != null && widget.heightPercent != null) {
      widgetWidth = screenWidth * widget.widthPercent!;
      widgetHeight = screenHeight * widget.heightPercent!;
    }

    Point center = Point(widgetWidth/2,widgetHeight/2);
    Point screenLocation = center + location;
    moleWidth = widgetWidth / 8;
    moleHeight = widgetWidth / 4;

    if (initialFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(seconds: 1)).then((value) {
          rndWalk(widgetWidth, widgetHeight, 36);
        });
      });
      initialFrame = false;
    }

    return Container(
        decoration: BoxDecoration(
          color: Colors.lightGreen,
          image: DecorationImage(
            image: ZugUtils.getAssetImage("images/moleboard.png"),
            fit: BoxFit.fill,
          ),
        ),
        width: widgetWidth,
        height: widgetHeight,
        child: Stack(//fit: StackFit.expand,
            children: [
          AnimatedPositioned(
            left: screenLocation.x as double,
            top: screenLocation.y as double,
            onEnd: () => rndWalk(widgetWidth, widgetHeight, min(widgetWidth,widgetHeight)/4),
            duration: Duration(milliseconds: widget.animationSpeed),
            curve: Curves.decelerate,
            child: AnimatedContainer(
              curve: Curves.easeIn,
              duration: Duration(milliseconds: (widget.animationSpeed/4).round()),
              transform: matrix,
              transformAlignment: Alignment.center,
              width: moleWidth,
              height: moleHeight,
              child: widget.moleImg,
            ),
          ),
              Container(
                  //color: Colors.green,
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(
                      width: widgetWidth/2,
                      height: widgetHeight/5,
                      child: FittedBox(child: Text(widget.caption, style: const TextStyle(backgroundColor: Colors.white))))
              ),
        ]));
  }

  void rndWalk(double width, double height, double speed) {
    double maxWidth = (width/2) - moleWidth;
    double minWidth = -(width/2);
    double maxHeight = (height/2) - moleHeight;
    double minHeight = -(height/2);
    double x = -speed + (Random().nextDouble() * (speed * 2));
    double y = -speed + (Random().nextDouble() * (speed * 2));

    double newX = location.x + x;
    if (newX < minWidth) {
      newX = minWidth;
    } else if (newX >= maxWidth) {
      newX = maxWidth;
    }
    double newY = location.y + y;
    if (newY < minHeight) {
      newY = minHeight;
    } else if (newY >= maxHeight) {
      newY = maxHeight;
    }

    rotZ = atan2(y, x) + pi;
    matrix = Matrix4.identity();
    matrix.setRotationZ(rotZ);
    if (x > 0) matrix.setRotationY(pi);

    setState(() {
      location = Point(newX,newY);
    });
  }
}
