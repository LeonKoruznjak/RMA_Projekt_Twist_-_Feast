import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/blank_pixel.dart';
import 'package:flutter_application_1/foodPixel.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/main_menu.dart';
import 'package:flutter_application_1/snake_pixel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

enum SnakeDirection { UP, DOWN, LEFT, RIGHT }

class _GamePageState extends State<GamePage> {
  int rowSize = 10;
  int totalNumberOfSquares = 100;

  // Funkcija za dohvaćanje highScore iz Firestore
  Future<void> fetchHighScore(String globalUid) async {
    if (globalUid != null && globalUid.isNotEmpty) {
      final firestore = FirebaseFirestore.instance;
      final docSnapshot =
          await firestore.collection('users').doc(globalUid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('highscore')) {
          highScore = data['highscore'] as int;
        }
      }
    }
  }

  //user score
  int currentScore = 0;
  List<int> snakePos = [0, 1, 2];
  var currentDirection = SnakeDirection.RIGHT;
  int foodPos = 55;
  bool gameStarted = false;

  Future updateHighScore() async {
    if (globalUid == null || globalUid!.isEmpty) {
      print('Global UID is not set. Cannot update highscore.');
      return;
    }

    try {
      var database = FirebaseFirestore.instance;

      var userDoc = await database.collection('users').doc(globalUid).get();
      print(globalUid);

      if (userDoc.exists) {
        await database.collection('users').doc(globalUid).update({
          "highscore": highScore?.toInt(),
        });
        print('Highscore updated successfully!');
      } else {
        print('User document does not exist. Cannot update highscore.');
      }
    } catch (e) {
      print('Failed to update highscore: $e');
    }
  }

  void startGame() {
    gameStarted = true;
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      setState(() {
        moveSnake();

        //check if the game is over
        if (gameOver()) {
          timer.cancel();
          if (currentScore > highScore!) {
            highScore = currentScore;
            updateHighScore();
          }

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(
                  "Game over!",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  "Your score is " + currentScore.toString(),
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                actions: [
                  // Gumb za novi početak igre
                  MaterialButton(
                    onPressed: () {
                      newGame(); // Poziva funkciju za novu igru
                      Navigator.pop(context); // Zatvara dijalog
                    },
                    child: Text("Close",
                        style: TextStyle(fontSize: 15, color: Colors.white)),
                    color: Colors.deepOrange,
                    // Postavlja boju gumba
                  ),
                ],
              );
            },
          );
        }
      });
    });
  }

  void newGame() {
    setState(() {
      //user score
      currentScore = 0;
      snakePos = [0, 1, 2];
      currentDirection = SnakeDirection.RIGHT;
      foodPos = 55;

      gameStarted = false;
    });
  }

  void eatFood() {
    currentScore++;
    while (snakePos.contains(foodPos)) {
      foodPos = Random().nextInt(totalNumberOfSquares);
    }
  }

  void moveSnake() {
    switch (currentDirection) {
      case SnakeDirection.RIGHT:
        if (snakePos.last % rowSize == 9) {
          snakePos.add(snakePos.last + 1 - rowSize);
        } else {
          snakePos.add(snakePos.last + 1);
        }
        break;
      case SnakeDirection.LEFT:
        if (snakePos.last % rowSize == 0) {
          snakePos.add(snakePos.last - 1 + rowSize);
        } else {
          snakePos.add(snakePos.last - 1);
        }
        break;
      case SnakeDirection.UP:
        if (snakePos.last < rowSize) {
          snakePos.add(snakePos.last - rowSize + totalNumberOfSquares);
        } else {
          snakePos.add(snakePos.last - rowSize);
        }
        break;
      case SnakeDirection.DOWN:
        if (snakePos.last + rowSize >= totalNumberOfSquares) {
          snakePos.add(snakePos.last + rowSize - totalNumberOfSquares);
        } else {
          snakePos.add(snakePos.last + rowSize);
        }
        break;
      default:
    }

    if (snakePos.last == foodPos) {
      eatFood();
    } else {
      snakePos.removeAt(0);
    }
  }

  bool gameOver() {
    List<int> snakeBody = snakePos.sublist(0, snakePos.length - 1);
    if (snakeBody.contains(snakePos.last)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(top: 70),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                //current score
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Current score:",
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      currentScore.toString(),
                      style: TextStyle(fontSize: 36, color: Colors.white),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "High score:",
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      highScore.toString(),
                      style: TextStyle(fontSize: 36, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          )),

          // game grid
          Expanded(
            flex: 3,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 0 &&
                    currentDirection != SnakeDirection.UP) {
                  currentDirection = SnakeDirection.DOWN;
                } else if (details.delta.dy < 0 &&
                    currentDirection != SnakeDirection.DOWN) {
                  currentDirection = SnakeDirection.UP;
                }
              },
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 0 &&
                    currentDirection != SnakeDirection.LEFT) {
                  currentDirection = SnakeDirection.RIGHT;
                } else if (details.delta.dx < 0 &&
                    currentDirection != SnakeDirection.RIGHT) {
                  currentDirection = SnakeDirection.LEFT;
                }
              },
              child: GridView.builder(
                itemCount: totalNumberOfSquares,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: rowSize),
                itemBuilder: (context, index) {
                  if (snakePos.contains(index)) {
                    return const SnakePixel();
                  } else if (foodPos == index) {
                    return const FoodPixel();
                  } else {
                    return const BlankPixel();
                  }
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // PLAY dugme
                    Container(
                      width: 150,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: gameStarted
                              ? [Colors.grey, Colors.grey[400]!]
                              : [Colors.green, Colors.lightGreen],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: gameStarted ? () {} : startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'PLAY',
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // MAIN MENU dugme
                    Container(
                      width: 150,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: [Colors.red, Colors.deepOrange],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return MainMenuPage();
                            }),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'MAIN MENU',
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
