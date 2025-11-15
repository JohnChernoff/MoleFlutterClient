import 'package:flutter/material.dart';
import 'package:mole_app/src/model/mole_model.dart';
import 'package:audioplayers/audioplayers.dart';

class MoleChessHelpPage extends StatefulWidget {
  final MoleModel model;
  const MoleChessHelpPage(this.model,{super.key});

  @override
  State<MoleChessHelpPage> createState() => _MoleChessHelpPageState();
}

class _MoleChessHelpPageState extends State<MoleChessHelpPage> {
  final Map<String, bool> expandedSections = {
    'overview': true,
    'roles': false,
    'voting': false,
    'moleActions': false,
    'strategy': false,
    'ui': false,
  };

  @override
  void initState() {
    super.initState();
    widget.model.playAudio(AssetSource("audio/tracks/intro.mp3"));
  }

  void toggleSection(String section) {
    setState(() {
      expandedSections[section] = !expandedSections[section]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(child: SizedBox(width: 240, height: 128, child:
        ElevatedButton(
            onPressed: () => widget.model.gotoMolePage(MolePage.lobby),
            child: Row(children: [
              Icon(Icons.keyboard_return),Text(" Back to Lobby")]
            )))),
        Expanded(child: helpPage())
      ],
    );
  }

  Widget helpPage() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 72,
          floating: false,
          pinned: true,
          backgroundColor: const Color(0xFF0B5569),
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: const Text(
              '🦡 MoleChess Help',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF164E63), Color(0xFF0E7490)],
                ),
              ),

            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Quick Overview
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2332).withOpacity(0.6),
                    border: Border.all(color: Colors.cyan, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What is MoleChess?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF67E8F9),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'MoleChess is a chess game where teams of players vote on each move together. One player on each team is secretly a Mole trying to sabotage their team in order to lose the game.',
                        style: TextStyle(
                          color: Color(0xFFD1D5DB),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The Mole can be removed by (unanimous) vote, but be careful - a team can only vote once and if they get it wrong, the mole can no longer be voted out! ',
                        style: TextStyle(
                          color: Colors.grey[400],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Help Sections
                _buildSection('overview', 'Game Overview', Icons.info_outline),
                _buildSection('roles', 'Secret Roles', Icons.people_outline),
                _buildSection('voting', 'Move Voting System', Icons.how_to_vote),
                _buildSection('moleActions', 'Mole Special Actions', Icons.psychology),
                _buildSection('strategy', 'Strategy & Tips', Icons.lightbulb_outline),
                _buildSection('ui', 'UI & Controls Guide', Icons.videogame_asset),
                const SizedBox(height: 24),
                // Footer
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    border: Border(
                      top: BorderSide(color: Colors.grey[800]!, width: 1),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎓 Ready to Play?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Join the lobby, create a game with your preferred settings, and prepare for a unique chess experience where voting, deception, and strategy collide.',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Remember: In MoleChess, the best move isn\'t always the best move! 🦡',
                        style: TextStyle(
                          color: Color(0xFF67E8F9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String id, String title, IconData icon) {
    final isExpanded = expandedSections[id] ?? false;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => toggleSection(id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF67E8F9), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              color: Colors.grey[900]?.withOpacity(0.3),
              padding: const EdgeInsets.all(16),
              child: _getSectionContent(id),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getSectionContent(String sectionId) {
    switch (sectionId) {
      case 'overview':
        return _buildOverviewSection();
      case 'roles':
        return _buildRolesSection();
      case 'voting':
        return _buildVotingSection();
      case 'moleActions':
        return _buildMoleActionsSection();
      case 'strategy':
        return _buildStrategySection();
      case 'ui':
        return _buildUISection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubheading('🎮 How It Works'),
        _buildBulletList([
          'Games are White vs. Black - two teams competing at chess',
          'Each team has a minimum of three players',
          'Every turn, all active players vote on the move to play',
          'The move with the most votes wins and is executed',
          'If multiple moves tie, one is chosen at random',
        ]),
        const SizedBox(height: 16),
        _buildSubheading('🏁 Winning Conditions'),
        _buildBulletList(
          [
            'Standard Chess Victory:',
            'Checkmate the opposing king',
            'Opponent resigns (by majority vote)',
            'Mole Victory (Sabotage):',
            'The Mole\'s team loses',
          ],
          fontSize: 13,
        ),
        const SizedBox(height: 16),
        _buildSubheading('📊 Game Phases'),
        _buildBulletList([
          'Pregame: Players join teams',
          'Voting: Each turn, players vote for moves by playing them on their board',
          'Postgame: Game review period before closing (default 60 seconds)',
        ]),
      ],
    );
  }

  Widget _buildRolesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRoleBox(
          role: 'The Mole',
          emoji: '🦡',
          goal: 'Goal: Lose the chess game while staying hidden',
          color: const Color(0xFFA855F7),
          details: [
            'One Mole per team (assigned randomly at game start)',
            'Knows their role immediately, others don\'t',
            'Can vote for moves like everyone else',
            'Earns points if their team loses at chess',
            'Can be voted out by their team (unanimous vote)',
            'If voted out, the Mole defects to the other side and becomes a regular player',
          ],
        ),
        const SizedBox(height: 16),
        _buildRoleBox(
          role: 'The Inspector (Optional)',
          emoji: '🔍',
          goal: 'Goal: Identify and vote out the Mole while winning at chess',
          color: const Color(0xFFFBBF24),
          details: [
            'One Inspector per team (if Inspector Role enabled)',
            'Does NOT know who the Mole is at the start',
            'Must deduce the Mole through observation and inspection',
            'Can inspect player moves after turn 12 (configurable)',
            '⚠️ Risk: When you inspect, you ALSO vote for a random move!',
            'Frequent inspections make you look suspicious to others',
            'Each inspection resets the inspection cooldown timer',
          ],
        ),
        const SizedBox(height: 16),
        _buildRoleBox(
          role: 'Regular Player',
          emoji: '♟️',
          goal: 'Goal: Win at chess and vote out the Mole',
          color: const Color(0xFF34D399),
          details: [
            'Majority of the team (everyone else)',
            'Doesn\'t know who the Mole or Inspector is',
            'Plays normally and votes for the best moves',
            'Must deduce the Mole from voting patterns and game behavior',
            'Can vote to eliminate suspected players',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoBox(
          '💡 Your role is revealed only to you when the game starts. Keep it secret unless you want to influence the game!',
        ),
      ],
    );
  }

  Widget _buildVotingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubheading('🗳️ How Voting Works Each Turn'),
        _buildNumberedList([
          'Voting Phase Starts - All active players can vote for a move by playing it on their board',
          'Move Tallying - The system counts votes in real-time',
          'Winner Selected - After the timer expires or everyone on the team votes, the most-voted move wins',
          'Move Executed - The winning move is played on the board',
          'Next Turn - Process repeats with the next team to move',
        ]),
        const SizedBox(height: 16),
        _buildSubheading('📋 The Move Votes Display'),
        _buildBulletList([
          'Selected Move (Top): Currently winning move (usually shown in green)',
          'Alternative Votes: Other moves proposed by other players',
          'Voter Colors: Each player\'s color dot shows who voted for what',
          'Move Count: Shows how many total votes there are',
        ]),
        const SizedBox(height: 16),
        _buildSubheading('⚙️ Vote Mechanics'),
        _buildBulletList([
          'One vote per player per turn on their team\'s move',
          'Can change your vote until time runs out',
          'Ties are broken randomly',
          'If all players vote, phase ends immediately (no waiting)',
          'Inactive/away players don\'t get a vote',
          'AI players always vote (bots fill empty slots)',
        ]),
        const SizedBox(height: 16),
        _buildSubheading('👁️ Vote Display Style Option'),
        Text(
          'If "Vote Display Style" is set to "hidden" you won\'t see other players\' moves in real-time. This makes it harder to identify patterns of sabotage.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildMoleActionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5B21B6).withOpacity(0.2),
        border: Border.all(color: const Color(0xFFA855F7), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🦡 Mole-Only Abilities',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFA855F7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildMoleAbility(
            '💣 Mole Bomb (optional, off by default)',
            [
              'Available after a certain number of moves',
              'When activated, the Mole can force their move to play regardless of votes',
              'Broadcasts to opponents that a "Mole Bomb" occurred',
              'Can only be used once per game',
            ],
          ),
          const SizedBox(height: 12),
          _buildMoleAbility(
            '📢 Rampage',
            [
              'Triggered when a vote occurs and the Mole is not voted out',
              'The exposed Mole is now immune from voting and can make terrible moves with impunity',
              'Opposing team\'s mole can attempt to veto a rampaging mole move',
            ],
          ),
          const SizedBox(height: 12),
          _buildMoleAbility(
            '🔄 Defection',
            [
              'If a Mole is voted out, they may switch teams',
              'Becomes a regular player on the opposing team',
              'Their role changes from Mole to Player',
              'Can help their new team win the game',
            ],
          ),
          const SizedBox(height: 12),
          _buildMoleAbility(
            '🎯 Mole Veto (Optional)',
            [
              'If enabled: a mole can veto an opposing Mole\'s move',
              'Costs: Must reveal one of their own previous moves',
              'Can only veto rampaging mole moves (or bombs)',
            ],
          ),
          const SizedBox(height: 12),
          _buildMoleAbility(
            '🔮 Move/Piece Prediction (Optional)',
            [
              'Moles can try to guess the opponent Mole\'s next move',
              'If correct, the predictor\'s role is revealed',
              'Creates psychological warfare between Moles',
            ],
          ),
          const SizedBox(height: 12),
          _buildMoleAbility(
            '🔎 Inspector Inspection',
            [
              'Only available to the Inspector role (one per team)',
              'Available after turn 12 (configurable)',
              'Reveals one of a player\'s previous moves from the move history',
              '🎲 Critical Cost: You automatically make a random move that turn',
              'Could help your team (good random luck) or hurt them (bad random vote)',
              'Each inspection resets the turn counter (must wait 12 more moves)',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubheading('♟️ For Regular Players'),
        _buildBulletList([
          'Play strong chess: Vote for objectively good moves',
          'Watch voting patterns: Who consistently votes for bad moves?',
          'Look for hesitation: Does someone always vote late or waffle?',
          'Communication: Use chat to coordinate with teammates',
          'Statistical analysis: Track centipawn loss for each player\'s suggestions',
          'Don\'t lynch innocent players: False accusations help the Mole',
          'Build consensus: Convince others before voting someone off',
        ]),
        const SizedBox(height: 16),
        _buildSubheading('🔍 For the Inspector'),
        _buildBulletList([
          'You don\'t know who the Mole is at first: You have to figure it out',
          'Watch voting patterns carefully: Who votes for suspicious moves?',
          'Use inspections strategically: After turn 12, start investigating suspicious players',
          'Understand the cost: Each inspection forces YOU to make a random vote',
          'Hide your analysis: Frequent inspections make you a target',
          'Build evidence: Gather multiple pieces of suspicious voting before accusing',
          'Coordinate with teammates: Plant seeds of doubt without revealing yourself',
          'Take calculated risks: Is one inspection worth potentially losing a turn with a bad vote?',
        ]),
        const SizedBox(height: 16),
        _buildSubheading('🦡 For the Mole'),
        _buildBulletList([
          'Blend in: Don\'t always vote for obviously terrible moves',
          'Varied voting: Sometimes vote good, sometimes bad',
          'Blame others: Suggest other players are sabotaging',
          'Create chaos: Vote off suspected Inspectors early',
          'Timing matters: Obvious sabotage gets you caught immediately',
          'Use bombs strategically: Save them for critical moments',
          'Misdirection: Make bad moves look like accidents or close calls',
          'Play off confusion: Everyone suspects each other anyway',
        ]),
        const SizedBox(height: 16),
        _buildInfoBox(
          '🎯 The Core Philosophy: Playing badly is often the best move when you\'re the Mole — but not TOO badly! The key is making sabotage look like a team mistake, not personal incompetence.',
        ),
      ],
    );
  }

  Widget _buildUISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubheading('🎮 Board & Voting'),
        _buildBulletList([
          'Click & Drag: Click a piece\'s starting square, drag to destination to propose a move',
          'Promotion: Select piece type when pawn reaches the back rank',
          'View Votes: See other players\' proposed moves (unless hidden)',
        ]),
        const SizedBox(height: 16),
        _buildSubheading('🎛️ Board Header Buttons'),
        _buildBulletList([
          'Role: Check your secret role (hidden from other players)',
          'Flip: Rotate board to play from your perspective',
          'Draw: Propose a draw (requires majority vote to accept)',
          'Resign: Give up (requires majority vote of your team)',
          'Veto: Reject the current move (Mole-only in veto phase)',
          'Inspect: Review opponent\'s moves (Inspector-only)',
          'PGN: Download game record',
        ]),
        const SizedBox(height: 16),
        _buildSubheading('📜 Move List Panel'),
        _buildBulletList([
          'Move Numbers: Shows all moves in the game',
          'Live Indicator: Camera icon shows current position',
          'Click to Review: Click any move to see voting details',
          'Arrows: Shows who voted for each move (color-coded)',
          'Keyboard: Arrow keys navigate move history',
        ]),
        const SizedBox(height: 16),
        _buildSubheading('⏱️ Chess Clock'),
        _buildBulletList([
          'Time Remaining: Seconds left in voting phase',
          'Progress Bar: Visual indicator of time pressure',
          'Team Color: Shows whose turn it is',
        ]),
        const SizedBox(height: 16),
        _buildSubheading('💬 Chat & Communication'),
        _buildBulletList([
          'Team Chat: Discuss strategy with your teammates',
          'Lobby Chat: Pre-game coordination',
          'Game Chat: Live communication during play',
          'Be Strategic: What you say can reveal your role!',
        ]),
        const SizedBox(height: 16),
        _buildSubheading('⚙️ Game Options'),
        _buildBulletList([
          'Streamer Mode: Hide your role from viewers (for streaming)',
          'Move Hover: Hover over moves to see voting details',
          'Piece Set: Choose mole or standard chess pieces',
          'Board Color: Customize board appearance',
          'Notifications: Control game alerts',
        ]),
      ],
    );
  }

  Widget _buildSubheading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBulletList(List<String> items, {double fontSize = 13}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          '• $item',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: fontSize,
            height: 1.4,
          ),
        ),
      ))
          .toList(),
    );
  }

  Widget _buildNumberedList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        items.length,
            (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${index + 1}. ${items[index]}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBox({
    required String role,
    required String emoji,
    required String goal,
    required Color color,
    required List<String> details,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji $role',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            goal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: details
                .map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $detail',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF).withOpacity(0.2),
        border: Border.all(color: Colors.blue, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF93C5FD),
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildMoleAbility(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: points
              .map((point) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Text(
              '• $point',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }
}
