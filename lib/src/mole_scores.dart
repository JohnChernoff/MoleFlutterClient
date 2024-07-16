import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:mole_app/src/mole_client.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_utils.dart';
import 'main_page.dart';
import 'dart:math' as math;

class MoleScorePage extends StatefulWidget {
  final MoleClient client;
  final List<Widget> buttons;
  const MoleScorePage(this.client,this.buttons,{super.key});

  @override
  State<StatefulWidget> createState() => _MoleScorePageState();

}

class _MoleScorePageState extends State<MoleScorePage> {
  Map<int,dynamic> scoreVars = {};
  double width = 1024; double height = 720;
  final random = math.Random();

  @override
  void initState() {
    super.initState(); //print(widget.client.topPlayers);
    for (int i = 0; i < widget.client.topPlayers.length; i++) {
      scoreVars.putIfAbsent(i, () => getScoreVars()); //print(scoreVars[i]);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1)).then((value) {
        for (var i in scoreVars.keys) { scoreVars[i] = getScoreVars(); }
        setState(() { });
        widget.client.playTrack("mole_score");
      });
    });
  }

  dynamic getScoreVars() {
    double w =  108 + random.nextDouble() * width/12;
    double h = 108 + random.nextDouble() * height/12;
    return {
      "duration": Duration(milliseconds: 1000 + math.Random().nextInt(5000)),
      "width" : w,
      "height" : h,
      "left": random.nextDouble() * (width - w),
      "top": random.nextDouble() * (height - h),
      "color": Color.fromRGBO(36 + random.nextInt(220),36 + random.nextInt(220),36 + random.nextInt(220),1),
      "radius": BorderRadius.circular(random.nextInt(100).toDouble())
    };
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = ZugUtils.getActualScreenHeight(context);
    return Container(
        color: Colors.black,
        width: width,
        height: height,
        child: Column(
          children: [
            Container(
                color: Colors.black,
                height: MainMolePage.headerHeight,
                child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: widget.buttons)),
            Expanded(
                child: Stack(
                  fit: StackFit.passthrough,
                  children: List.generate(scoreVars.length, (i) => AnimatedPositioned(
                      duration: scoreVars[i]["duration"],
                      left: scoreVars[i]["left"],
                      top: scoreVars[i]["top"],
                      onEnd: () {
                        setState(() {
                          scoreVars[i] = getScoreVars();
                        });
                      },
                      child: AnimatedContainer(
                          decoration: BoxDecoration(
                            color: scoreVars[i]["color"],
                            borderRadius: scoreVars[i]["radius"],
                          ),
                          duration: scoreVars[i]["duration"],
                          width: scoreVars[i]['width'],
                          height: scoreVars[i]['height'],
                          child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("${i + 1}"),
                                  Text("${widget.client.topPlayers.get(i)[fieldName]}"),
                                  Text("${widget.client.topPlayers.get(i)['rating']}")
                                ]
                              )
                          )
                      )
                  )),
            ))
          ],
        ));
  }

}