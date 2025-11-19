import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enum for different game result types
enum GameResult { win, loss, draw }

/// Main game result animation widget
class GameResultAnimation extends StatefulWidget {
  final GameResult result;
  final String title;
  final String subtitle;
  final VoidCallback? onDismiss;
  final Widget? backgroundImage;
  final Color? accentColor;

  const GameResultAnimation({
    required this.result,
    required this.title,
    required this.subtitle,
    this.onDismiss,
    this.backgroundImage,
    this.accentColor,
    super.key,
  });

  @override
  State<GameResultAnimation> createState() => _GameResultAnimationState();
}

class _GameResultAnimationState extends State<GameResultAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final math.Random _random = math.Random();
  List<ParticleData> particles = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateParticles();
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Scale animation with overshoot effect
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    // Rotation animation
    _rotateAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.6)),
    );

    // Slide up animation
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _mainController.forward();
    _particleController.repeat();
  }

  void _generateParticles() {
    final count = widget.result == GameResult.draw ? 20 : 30;
    for (int i = 0; i < count; i++) {
      particles.add(
        ParticleData(
          angle: _random.nextDouble() * math.pi * 2,
          velocity: 50 + _random.nextDouble() * 200,
          size: 4 + _random.nextDouble() * 12,
          duration: Duration(
            milliseconds: 1200 + _random.nextInt(600),
          ),
          delay: Duration(milliseconds: _random.nextInt(400)),
        ),
      );
    }
  }

  Color _getResultColor() {
    switch (widget.result) {
      case GameResult.win:
        return widget.accentColor ?? Colors.green;
      case GameResult.loss:
        return widget.accentColor ?? Colors.red;
      case GameResult.draw:
        return widget.accentColor ?? Colors.amber;
    }
  }

  IconData _getResultIcon() {
    switch (widget.result) {
      case GameResult.win:
        return Icons.emoji_events;
      case GameResult.loss:
        return Icons.sentiment_dissatisfied;
      case GameResult.draw:
        return Icons.handshake;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background
        if (widget.backgroundImage != null)
          Positioned.fill(child: widget.backgroundImage!)
        else
          Container(
            color: Colors.black87,
          ),

        // Particle effects
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: particles,
                  progress: _particleController.value,
                  color: _getResultColor(),
                ),
              );
            },
          ),
        ),

        // Main content
        AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Result icon with glow effect
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getResultColor().withOpacity(0.6),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  _getResultIcon(),
                  size: 100,
                  color: _getResultColor(),
                ),
              ),
              const SizedBox(height: 30),

              // Title
              Text(
                widget.title,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black54,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                widget.subtitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _getResultColor(),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Dismiss button
              ElevatedButton.icon(
                onPressed: widget.onDismiss,
                icon: const Icon(Icons.check_circle),
                label: const Text('Continue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getResultColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }
}

/// Particle data for effects
class ParticleData {
  final double angle;
  final double velocity;
  final double size;
  final Duration duration;
  final Duration delay;

  ParticleData({
    required this.angle,
    required this.velocity,
    required this.size,
    required this.duration,
    required this.delay,
  });

  Offset getPosition(double progress) {
    final adjustedProgress =
    ((progress * 1000 - delay.inMilliseconds) / duration.inMilliseconds)
        .clamp(0.0, 1.0);

    if (adjustedProgress == 0.0) return Offset.zero;

    // Ease out for a nice deceleration effect
    final easeProgress = 1 - (1 - adjustedProgress) * (1 - adjustedProgress);

    final distance = velocity * easeProgress;
    return Offset(
      distance * math.cos(angle),
      distance * math.sin(angle),
    );
  }

  double getOpacity(double progress) {
    final adjustedProgress =
    ((progress * 1000 - delay.inMilliseconds) / duration.inMilliseconds)
        .clamp(0.0, 1.0);

    if (adjustedProgress < 0.7) return 1.0;
    return 1.0 - (adjustedProgress - 0.7) / 0.3;
  }
}

/// Custom painter for particle effects
class ParticlePainter extends CustomPainter {
  final List<ParticleData> particles;
  final double progress;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final position = particle.getPosition(progress);
      final opacity = particle.getOpacity(progress);
      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        center + position,
        particle.size / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

/// Example usage in your game_page.dart
class GameResultDialogExample extends StatelessWidget {
  const GameResultDialogExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GameResultAnimation(
        result: GameResult.win,
        title: 'White Wins!',
        subtitle: 'Victory is yours',
        onDismiss: () => Navigator.pop(context),
        accentColor: Colors.green,
        backgroundImage: Image(
          image: AssetImage('images/mole_sprite_white.gif'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}