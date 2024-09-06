import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class StarWarsGame extends StatefulWidget {

  const StarWarsGame({required this.requiredScore, required this.onGameOver, super.key});
  final int requiredScore;
  final Function onGameOver;

  @override
  _StarWarsGameState createState() => _StarWarsGameState();
}

class _StarWarsGameState extends State<StarWarsGame> with TickerProviderStateMixin {
  late double playerX;
  List<AnimatedEnemy> enemies = [];
  List<Bullet> bullets = [];
  int score = 0;
  bool isPlaying = false;
  Random random = Random();
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    playerX = 0;
    print('StarWarsGame initialized');
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    for (final enemy in enemies) {
      enemy.controller.dispose();
    }
    super.dispose();
  }

  void startGame() {
    print('Starting game');
    if (mounted) {
      setState(() {
        enemies.clear();
        bullets.clear();
        score = 0;
        isPlaying = true;
      });
    }

    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!isPlaying) {
        timer.cancel();
        return;
      }
      _updateGame();
    });
  }

  void _updateGame() {
    if (!mounted) return;
    setState(() {
      _moveEnemies();
      _moveBullets();
      _checkCollisions();
      _spawnEnemy();
    });
  }

  void _spawnEnemy() {
    if (random.nextDouble() < 0.05) {
      final enemy = AnimatedEnemy(x: random.nextDouble() * 2 - 1, y: -1.1);
      enemy.startAnimation(this);
      enemies.add(enemy);
    }
  }

  void _moveEnemies() {
    for (final enemy in enemies) {
      enemy.y += 0.02;
    }
    enemies.removeWhere((enemy) => enemy.y > 1.1);
  }

  void _moveBullets() {
    for (final bullet in bullets) {
      bullet.y -= 0.05;
    }
    bullets.removeWhere((bullet) => bullet.y < -1.1);
  }

  void _checkCollisions() {
    for (final bullet in bullets) {
      for (final enemy in enemies) {
        if ((bullet.x - enemy.x).abs() < 0.05 && (bullet.y - enemy.y).abs() < 0.05) {
          bullet.hit = true;
          enemy.hit = true;
          score++;
          _showExplosion(Offset((enemy.x + 1) * MediaQuery.of(context).size.width / 2, 
                                enemy.y * MediaQuery.of(context).size.height,),);
          if (score >= widget.requiredScore) {
            _endGame(true);
          }
        }
      }
    }

    bullets.removeWhere((bullet) => bullet.hit);
    enemies.removeWhere((enemy) {
      if (enemy.hit) {
        enemy.controller.dispose();
        return true;
      }
      return false;
    });

    if (enemies.any((enemy) => enemy.y > 0.9)) {
      _endGame(false);
    }
  }

  void _shoot() {
    bullets.add(Bullet(x: playerX, y: 0.9));
  }

  void _endGame(bool success) {
    print('Game ended. Success: $success, Score: $score');
    if (mounted) {
      setState(() {
        isPlaying = false;
      });
    }
    gameTimer?.cancel();
    widget.onGameOver(score);
  }

  void _showExplosion(Offset position) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => ExplosionEffect(position: position),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/space_background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'זמן להתעורר!',
                      style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'ניקוד: $score / ${widget.requiredScore}',
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isPlaying
                    ? GamePlayArea(
                        playerX: playerX,
                        enemies: enemies,
                        bullets: bullets,
                        onShoot: _shoot,
                        onMove: _handleMove,
                      )
                    : Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: startGame,
                          child: const Text('התחל משחק', style: TextStyle(fontSize: 24)),
                        ),
                      ),
              ),
              if (isPlaying)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => _endGame(false),
                    child: const Text('סיים משחק', style: TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMove(double dx) {
    if (mounted) {
      setState(() {
        playerX += dx;
        playerX = playerX.clamp(-1.0, 1.0);
      });
    }
  }
}

class GamePlayArea extends StatelessWidget {

  const GamePlayArea({
    required this.playerX, required this.enemies, required this.bullets, required this.onShoot, required this.onMove, super.key,
  });
  final double playerX;
  final List<AnimatedEnemy> enemies;
  final List<Bullet> bullets;
  final VoidCallback onShoot;
  final void Function(double) onMove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) => onMove(details.delta.dx / context.size!.width),
      onTapDown: (_) => onShoot(),
      child: CustomPaint(
        painter: GamePainter(playerX, enemies, bullets),
        size: Size.infinite,
      ),
    );
  }
}

class GamePainter extends CustomPainter {

  GamePainter(this.playerX, this.enemies, this.bullets);
  final double playerX;
  final List<AnimatedEnemy> enemies;
  final List<Bullet> bullets;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawPlayer(canvas, size);
    _drawEnemies(canvas, size);
    _drawBullets(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white;
    final random = Random();
    for (var i = 0; i < 100; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        random.nextDouble() * 2,
        starPaint,
      );
    }
  }

  void _drawPlayer(Canvas canvas, Size size) {
    final playerPaint = Paint()..color = Colors.blue;
    final flamePaint = Paint()..color = Colors.orange;

    final shipPath = Path()
      ..moveTo((playerX + 1) * size.width / 2, size.height * 0.9)
      ..lineTo((playerX + 1) * size.width / 2 - size.width / 30, size.height * 0.97)
      ..lineTo((playerX + 1) * size.width / 2 + size.width / 30, size.height * 0.97)
      ..close();

    final flamePath = Path()
      ..moveTo((playerX + 1) * size.width / 2 - size.width / 60, size.height * 0.97)
      ..lineTo((playerX + 1) * size.width / 2, size.height)
      ..lineTo((playerX + 1) * size.width / 2 + size.width / 60, size.height * 0.97)
      ..close();

    canvas.drawPath(shipPath, playerPaint);
    canvas.drawPath(flamePath, flamePaint);
  }

  void _drawEnemies(Canvas canvas, Size size) {
    final enemyPaint = Paint()..color = Colors.red;
    for (final enemy in enemies) {
      final enemyPath = Path()
        ..moveTo((enemy.x + 1) * size.width / 2, enemy.y * size.height)
        ..lineTo((enemy.x + 1) * size.width / 2 - size.width / 40, (enemy.y + 0.03) * size.height)
        ..lineTo((enemy.x + 1) * size.width / 2 + size.width / 40, (enemy.y + 0.03) * size.height)
        ..close();
      canvas.drawPath(enemyPath, enemyPaint);
      
      // Draw animated part
      final animatedPart = Paint()
        ..color = Colors.yellow.withOpacity(enemy.animation.value);
      canvas.drawCircle(
        Offset((enemy.x + 1) * size.width / 2, (enemy.y + 0.015) * size.height),
        size.width / 80,
        animatedPart,
      );
    }
  }

  void _drawBullets(Canvas canvas, Size size) {
    final bulletPaint = Paint()..color = Colors.green;
    for (final bullet in bullets) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset((bullet.x + 1) * size.width / 2, bullet.y * size.height),
          width: size.width / 100,
          height: size.height / 50,
        ),
        bulletPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedEnemy {

  AnimatedEnemy({required this.x, required this.y});
  double x;
  double y;
  bool hit = false;
  late Animation<double> animation;
  late AnimationController controller;

  void startAnimation(TickerProvider vsync) {
    controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: vsync,
    );
    animation = Tween<double>(begin: 0, end: 1).animate(controller);
    controller.repeat(reverse: true);
  }
}

class Bullet {

  Bullet({required this.x, required this.y});
  double x;
  double y;
  bool hit = false;
}

class ExplosionEffect extends StatefulWidget {

  const ExplosionEffect({required this.position, super.key});
  final Offset position;

  @override
  _ExplosionEffectState createState() => _ExplosionEffectState();
}

class _ExplosionEffectState extends State<ExplosionEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward().then((_) => Navigator.of(context).pop());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: ExplosionPainter(
            position: widget.position,
            progress: _animation.value,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class ExplosionPainter extends CustomPainter {

  ExplosionPainter({required this.position, required this.progress});
  final Offset position;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.withOpacity(1 - progress)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 20 * progress, paint);

    final particlePaint = Paint()
      ..color = Colors.red.withOpacity(1 - progress)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 8; i++) {
      final angle = i * 45 * pi / 180;
      final x = position.dx + cos(angle) * 30 * progress;
      final y = position.dy + sin(angle) * 30 * progress;
      canvas.drawCircle(Offset(x, y), 5 * (1 - progress), particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}