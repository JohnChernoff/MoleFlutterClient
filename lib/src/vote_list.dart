import 'package:flutter/material.dart';
import 'package:zug_utils/zug_utils.dart';
import 'package:zugclient/zug_fields.dart';
import 'package:zugclient/zug_user.dart';

Widget buildVoteDisplay(Map<String,dynamic> votes, double screenWidth, double screenHeight) {
  final selected = votes['selected'];
  final alts = votes['alts'] ?? [];
  final selectedColor = HexColor.fromHex(selected[fieldPlayer][fieldChatColor].toString());
  final selectedPlayerName = UniqueName.fromData(selected[fieldPlayer][fieldUser]).name;

  return Container(
    color: Colors.black,
    width: screenWidth,
    height: screenHeight,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.how_to_vote, color: selectedColor, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move Votes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  selected['move']['san'] ?? '?',
                  style: TextStyle(
                    fontSize: 16,
                    color: selectedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Text(
                '${1 + alts.length} vote${1 + alts.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Selected move (prominent)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selectedColor.withOpacity(0.12),
            border: Border.all(color: selectedColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SELECTED MOVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selectedColor,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                selected['move']['san'] ?? '?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: selectedColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Voted by $selectedPlayerName',
                style: TextStyle(
                  fontSize: 14,
                  color: selectedColor.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        // Alternative votes
        if (alts.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Alternative Votes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...alts.map((alt) {
            final altColor = HexColor.fromHex(alt[fieldPlayer][fieldChatColor].toString());
            final altPlayerName = UniqueName.fromData(alt[fieldPlayer][fieldUser]).name;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: altColor.withOpacity(0.08),
                  border: Border(
                    left: BorderSide(color: altColor.withOpacity(0.6), width: 3),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: altColor.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          alt['move']['san'] ?? '?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: altColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      altPlayerName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ],
    ),
  );
}

