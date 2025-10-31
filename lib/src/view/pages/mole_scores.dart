import 'package:audioplayers/audioplayers.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../model/mole_model.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_fields.dart';
import 'dart:math' as math;

class MoleScorePage extends StatefulWidget {
  final MoleModel model;
  const MoleScorePage(this.model,{super.key});
  @override
  State<StatefulWidget> createState() => _MoleScorePageState();
}

class _MoleScorePageState extends State<MoleScorePage> {
  List<dynamic> topPlayers = []; //reversed for stack overlapping
  Map<int,dynamic> scoreVars = {};
  double width = 1024; double height = 720;
  final random = math.Random();

  @override
  void initState() {
    super.initState(); //print(widget.client.topPlayers);
    topPlayers = widget.model.topPlayers.reversed.toList();
    for (int i = 0; i < topPlayers.length; i++) {
      scoreVars.putIfAbsent(i, () => getScoreVars()); //print(scoreVars[p]);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var i in scoreVars.keys) { scoreVars[i] = getScoreVars(); }
      setState(() { });
      widget.model.playAudio(AssetSource("audio/tracks/fugue.mp3")); //mole_score.mp3"));
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
    if (widget.model.topPlayers.isEmpty) {
      return Center(child: ElevatedButton(
          onPressed: () => widget.model.gotoMolePage(MolePage.lobby),
          child: Text("Scores not found")));
    }
    width = MediaQuery.of(context).size.width;
    height = ZugUtils.getActualScreenHeight(context);
    return InkWell(child: Container(
        color: Colors.black,
        width: width,
        height: height,
        child: Column(
          children: [
            Container(
                color: Colors.black,
                height: MoleApp.headerHeight,
                child: ListView(
                    scrollDirection: Axis.horizontal)),
                    //children: widget.buttons)),
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
                                  Text("${topPlayers.length - i}"),
                                  Text("${topPlayers.get(i)[fieldName]}"),
                                  Text("${topPlayers.get(i)['rating']}")
                                ]
                              )
                          )
                      )
                  )),
            ))
          ],
        )),
      onTap: () => widget.model.gotoMolePage(MolePage.lobby),
    );
  }

}