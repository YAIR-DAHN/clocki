import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class SnakeGame extends StatefulWidget {
  final int requiredScore;
  final Function onGameOver;

  const SnakeGame({Key? key, required this.requiredScore, required this.onGameOver}) : super(key: key);

  @override
  _SnakeGameState createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static List<int> snakePosition = [45, 65, 85, 105, 125];
  int food = 0;
  int score = 0;
  static var random = Random();
  static var direction = 'down';
  bool isPlaying = false;
  bool gameStarted = false;
  bool gameFinished = false;

  @override
  void initState() {
    super.initState();
    generateNewFood();
  }

  void startGame() {
    setState(() {
      snakePosition = [45, 65, 85, 105, 125];
      direction = 'down';
      score = 0;
      isPlaying = true;
      gameStarted = true;
      gameFinished = false;
    });
    const duration = Duration(milliseconds: 300);
    Timer.periodic(duration, (Timer timer) {
      if (isPlaying) {
        updateSnake();
        if (gameOver()) {
          timer.cancel();
          endGame();
        }
      }
    });
  }

  void generateNewFood() {
    food = random.nextInt(400);
    while (snakePosition.contains(food)) {
      food = random.nextInt(400);
    }
  }

  void updateSnake() {
    setState(() {
      switch (direction) {
        case 'down':
          if (snakePosition.last > 380) {
            snakePosition.add(snakePosition.last % 20);
          } else {
            snakePosition.add(snakePosition.last + 20);
          }
          break;
        case 'up':
          if (snakePosition.last < 20) {
            snakePosition.add(snakePosition.last - 20 + 400);
          } else {
            snakePosition.add(snakePosition.last - 20);
          }
          break;
        case 'right':
          if (snakePosition.last % 20 == 0) {
            snakePosition.add(snakePosition.last + 19);
          } else {
            snakePosition.add(snakePosition.last - 1);
          }
          break;
        case 'left':
          if ((snakePosition.last + 1) % 20 == 0) {
            snakePosition.add(snakePosition.last - 19);
          } else {
            snakePosition.add(snakePosition.last + 1);
          }
          break;
      }

      if (snakePosition.last == food) {
        generateNewFood();
        score += 1;
        if (score >= widget.requiredScore) {
          endGame(success: true);
        }
      } else {
        snakePosition.removeAt(0);
      }
    });
  }

  bool gameOver() {
    for (int i = 0; i < snakePosition.length - 1; i++) {
      if (snakePosition.last == snakePosition[i]) {
        return true;
      }
    }
    return false;
  }

  void endGame({bool success = false}) {
    setState(() {
      isPlaying = false;
      gameFinished = true;
      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('כל הכבוד!'),
              content: Text('סיימת בהצלחה,כעת ניתן לכבות את ההתראה'),
              actions: <Widget>[
                TextButton(
                  child: Text('כיבוי'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onGameOver(score);
                  },
                ),
              ],
            );
          },
        );
      } else {
        widget.onGameOver(score);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[900]!, Colors.blue[300]!],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (!gameStarted)
            ElevatedButton(
              child: Text(
                'התחל משחק',
                style: TextStyle(fontSize: 24),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: startGame,
            )
          else
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (direction != 'up' && details.delta.dy > 0) {
                      direction = 'down';
                    } else if (direction != 'down' && details.delta.dy < 0) {
                      direction = 'up';
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                    if (direction != 'left' && details.delta.dx > 0) {
                      direction = 'right';
                    } else if (direction != 'right' && details.delta.dx < 0) {
                      direction = 'left';
                    }
                  },
                  child: GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: 400,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 20,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      if (snakePosition.contains(index)) {
                        return Center(
                          child: Container(
                            padding: EdgeInsets.all(2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Container(
                                color: Colors.greenAccent,
                              ),
                            ),
                          ),
                        );
                      }
                      if (index == food) {
                        return Container(
                          padding: EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          padding: EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Container(color: Colors.transparent),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          SizedBox(height: 20),
          Text(
            'ניקוד: $score / ${widget.requiredScore}',
            style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}