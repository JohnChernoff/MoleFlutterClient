import 'package:flutter/material.dart';
import 'package:zugclient/zug_model.dart';
import 'mole_client.dart';
import 'mole_fields.dart';

class ChessClock extends StatefulWidget {
  final MoleClient client;
  final Color bkgColor;
  final double width;
  final double height;
  const ChessClock(this.client,this.width,this.height,this.bkgColor,{super.key});

  @override
  State<StatefulWidget> createState() => _ChessClockState();
}

class _ChessClockState extends State<ChessClock> {
  double currentTime = 0;
  SideToMove side = SideToMove.black;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _countdownLoop(20);
    });
  }

  @override
  Widget build(BuildContext context) {
    double? value = progress > 0 ? progress : null;
    return Container(
      color: widget.bkgColor,
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          CustomPaint(
            painter: ClockPainter(side == SideToMove.black ? Colors.black : Colors.white),
          ),
          CircularProgressIndicator(
            strokeAlign: -1,
            strokeWidth: 16,
            backgroundColor: Colors.red,
            color: Colors.green,
            value: value,
            semanticsLabel: 'Circular progress indicator',
          ),
          Center(
              child: Text(
                "${currentTime.round()}",
                style: TextStyle(
                  fontSize: currentTime > 99 ? 24 : 42,
                  color: side == SideToMove.black ? Colors.white : Colors.black,
                ),
              )),
        ],
      ),
    );
  }

  void _countdownLoop(int millis) async {
    WidgetsFlutterBinding.ensureInitialized();
    ZugModel.log.fine("Starting countdown"); //int tick = 0;
    while (mounted) {
      await Future.delayed(Duration(milliseconds: millis), () {
        if (mounted) {
          MoleGame g = widget.client.getCurrentGame();
          setState(() {
            currentTime = g.phaseTimeRemaining() / 1000;
            progress =  g.phaseProgress();
            side = g.sideToMove();
          });
        }
      });
    }
    ZugModel.log.fine("Ending countdown");
  }
}

class ClockPainter extends CustomPainter {

  final Paint p = Paint();
  ClockPainter(Color color) {
    p.color = color;
    p.style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) { //print("Size: $size");
    canvas.drawCircle(Offset(size.width/2,size.width/2), size.shortestSide/2, p);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}