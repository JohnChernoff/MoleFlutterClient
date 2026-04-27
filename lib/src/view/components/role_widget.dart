import 'dart:math';

import 'package:flutter/material.dart';

import '../../model/mole_fields.dart';

enum MoleRole { mole, player, inspector }

class SecretData {
  final MoleRole role;
  final int points;
  final String? secretPiece;   // FEN symbol e.g. 'q', 'R'
  final String? secretSquare;  // e.g. 'e4'
  final BountyData? bounty;

  const SecretData({
    required this.role,
    required this.points,
    this.secretPiece,
    this.secretSquare,
    this.bounty,
  });

  factory SecretData.fromJson(Map<String, dynamic> data) {
    final bountyJson = data[MoleFields.bounty] as Map<String, dynamic>?;
    return SecretData(
      role: MoleRole.values.firstWhere(
            (r) => r.name.toUpperCase() == (data[MoleFields.role] as String).toUpperCase(),
      ),
      points: data[MoleFields.points] as int,
      secretPiece: data[MoleFields.piece] as String?,
      secretSquare: data[MoleFields.square] as String?,
      bounty: bountyJson != null ? BountyData.fromJson(bountyJson) : null,
    );
  }
}

class BountyData {
  final String piece;
  final String square;

  const BountyData({required this.piece, required this.square});

  factory BountyData.fromJson(Map<String, dynamic> data) => BountyData(
    piece: data[MoleFields.piece] as String,
    square: data[MoleFields.square] as String,
  );
}

class SecretCard extends StatelessWidget {
  final SecretData roleData;

  const SecretCard({super.key, required this.roleData});

  // --- Role theming ---
  _RoleTheme get _theme => switch (roleData.role) {
    MoleRole.mole => _RoleTheme(
      label: 'Mole',
      icon: '🕵',
      description: 'You are secretly working against your own team. '
          'Fulfill your objectives without being caught.',
      color: const Color(0xFFB45309),
      bg: const Color(0xFFFEF3C7),
      border: const Color(0xFFF59E0B),
    ),
    MoleRole.player => _RoleTheme(
      label: 'Player',
      icon: '♟',
      description: 'Play for your team and complete your objectives '
          'to prove your loyalty.',
      color: const Color(0xFF1D4ED8),
      bg: const Color(0xFFEFF6FF),
      border: const Color(0xFF60A5FA),
    ),
    MoleRole.inspector => _RoleTheme(
      label: 'Inspector',
      icon: '🔍',
      description: 'You have authority to investigate teammates. '
          'Find the mole before it\'s too late.',
      color: const Color(0xFF6D28D9),
      bg: const Color(0xFFF5F3FF),
      border: const Color(0xFFA78BFA),
    ),
  };

  // --- Chess helpers ---
  static const _fenToUnicode = {
    'K': '♔', 'Q': '♕', 'R': '♖', 'B': '♗', 'N': '♘', 'P': '♙',
    'k': '♚', 'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟',
  };

  static const _fenToName = {
    'K': 'King',   'Q': 'Queen',  'R': 'Rook',
    'B': 'Bishop', 'N': 'Knight', 'P': 'Pawn',
    'k': 'King',   'q': 'Queen',  'r': 'Rook',
    'b': 'Bishop', 'n': 'Knight', 'p': 'Pawn',
  };

  String _pieceSymbol(String fen) => _fenToUnicode[fen] ?? fen;
  String _pieceName(String fen) => _fenToName[fen] ?? fen;
  //String _pieceSide(String fen) => fen == fen.toUpperCase() ? 'White' : 'Black';

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    return LayoutBuilder(builder: (ctx,bc) =>
        SizedBox(
            width: max(bc.maxWidth/3,480),
            height: max(bc.maxHeight/3,480),
            child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: t.border.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Points: ${roleData.points}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white, //Colors.grey.shade600,
                height: 2,
            )),
            _RoleBadge(theme: t),
            const SizedBox(height: 12),
            Text(
              t.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white, //Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Text(
              'SECRET OBJECTIVES',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SecretTile(
                    label: 'Piece',
                    value: roleData.secretPiece != null
                        ? _pieceSymbol(roleData.secretPiece!)
                        : '—',
                    subtitle: roleData.secretPiece != null
                        ? //'${_pieceSide(roleData.secretPiece!)} '
                    _pieceName(roleData.secretPiece!)
                        : '',
                    valueFontSize: 28,
                  ),
                ),
                Expanded(
                  child: _SecretTile(
                    label: 'Square',
                    value: roleData.secretSquare?.toUpperCase() ?? '—',
                    subtitle: 'target',
                  ),
                ),
                const SizedBox(width: 8),
              ],
            )),
            if (roleData.bounty != null) ...[
              const SizedBox(height: 8),
              _BountyTile(
                symbol: _pieceSymbol(roleData.bounty!.piece),
                description:
                //'${_pieceSide(roleData.bounty!.piece)} '
                    '${_pieceName(roleData.bounty!.piece)} '
                    'on ${roleData.bounty!.square.toUpperCase()}',
              ),
            ],
          ],
        ),
      ),
    )));
  }
}

// --- Sub-widgets ---

class _RoleTheme {
  final String label, icon, description;
  final Color color, bg, border;
  const _RoleTheme({
    required this.label,
    required this.icon,
    required this.description,
    required this.color,
    required this.bg,
    required this.border,
  });
}

class _RoleBadge extends StatelessWidget {
  final _RoleTheme theme;
  const _RoleBadge({required this.theme});

  @override
  Widget build(BuildContext context) {
    final themeTxtStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: theme.color,
    );
    final genericTxtStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(theme.icon, style: const TextStyle(fontSize: 22, color: Colors.black)),
          const SizedBox(width: 8),
          Text("Your Role ->", style: genericTxtStyle),
          const SizedBox(width: 8),
          Text(theme.label, style: themeTxtStyle),
        ],
      ),
    );
  }
}

class _SecretTile extends StatelessWidget {
  final String label, value, subtitle;
  final double valueFontSize;

  const _SecretTile({
    required this.label,
    required this.value,
    required this.subtitle,
    this.valueFontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  color: Colors.black)), //Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: valueFontSize, fontWeight: FontWeight.w600, color: Colors.black)),
          if (subtitle.isNotEmpty)
            Text(subtitle,
                style:
                TextStyle(fontSize: 11, color: Colors.black)), //grey.shade500)),
        ],
      ),
    );
  }
}

class _BountyTile extends StatelessWidget {
  final String symbol, description;
  const _BountyTile({required this.symbol, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          Text(symbol, style: const TextStyle(color: Colors.black, fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BOUNTY — CAPTURE THIS',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      color: Colors.red.shade400)),
              const SizedBox(height: 2),
              Text(description,
                  style: const TextStyle(color: Colors.black,
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
