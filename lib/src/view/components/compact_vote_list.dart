import 'package:flutter/material.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_user.dart';

class CompactVoteList extends StatelessWidget {
  final Map<String, dynamic> votes;
  final double? width, height;
  final fontSize = 16.0;

  const CompactVoteList(this.votes, {this.width, this.height, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.black,
        width: width,
        height: height,
        padding: const EdgeInsets.all(8),
        child: getVoteColumn()
    );
  }

  Widget getVoteColumn() {
    return FittedBox(child: Column(
      children: [
       getSelected(),
       SizedBox(height: 8),
       getAlts(),
      ],
    ));
  }

  Widget getSelected() {
    final selected = votes['selected'];
    final alts = votes['alts'] ?? [];
    final selectedColor = HexColor.fromHex(
        selected[fieldPlayer][fieldChatColor].toString());
    final selectedPlayerName = UniqueName
        .fromData(selected[fieldPlayer][fieldUser])
        .name;
    return Row(
      children: [
        Icon(Icons.how_to_vote, color: selectedColor, size: 16),
        const SizedBox(width: 6),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selected['move']['san'] ?? '?',
                style: TextStyle(
                  fontSize: fontSize * 1.2,
                  fontWeight: FontWeight.bold,
                  color: selectedColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                selectedPlayerName,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.grey[400],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.green, width: 0.5),
          ),
          child: Text(
            '${1 + alts.length}',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: fontSize * .8,
            ),
          ),
        ),
      ],
    );
  }

  Widget getAlts() {
    final alts = votes['alts'] ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: alts.map<Widget>((alt) {
        final altColor = HexColor.fromHex(
            alt[fieldPlayer][fieldChatColor].toString());
        final altPlayerName = UniqueName
            .fromData(alt[fieldPlayer][fieldUser]).name;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: altColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                alt['move']['san'] ?? '?',
                style: TextStyle(
                  fontSize: fontSize * .8,
                  fontWeight: FontWeight.w600,
                  color: altColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 4),
              Text(
                altPlayerName,
                style: TextStyle(
                  fontSize: fontSize * .75,
                  color: Colors.grey[400],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

}
