import 'dart:core';
import 'package:flutter/material.dart';
import 'package:format/format.dart';
import 'package:flame_audio/flame_audio.dart';
import 'dot.dart';
import 'line.dart';
import 'box.dart';
import 'player.dart';
import 'utils.dart';
import 'draw_dots.dart';
import 'draw_boxes.dart';

enum Direction { n, e, s, w }
enum Who { nobody, p1, p2 }
typedef Coord = (int x, int y);

int numberOfDots = 30;
late int dotsHorizontal;
late int dotsVertical;

final Map<Who, Player> players = {
  Who.nobody: Player("", Colors.transparent),
  Who.p1: Player("Player 1", Colors.redAccent),
  Who.p2: Player("Player 2", Colors.blue),
};

class DotsAndBoxesGame extends StatefulWidget {
  const DotsAndBoxesGame({super.key});

  @override
  State<DotsAndBoxesGame> createState() => _DotsAndBoxesGame();
}

class _DotsAndBoxesGame extends State<DotsAndBoxesGame> {
  late final AudioPool yayPool;
  late Set<Dot> dots;
  late Set<Line> lines;
  late Set<Box> boxes;
  late Who currentPlayer;
  late String winnerText;
  late bool showRestartConfirmation;
  late bool gameStarted;

  @override
  void initState() {
    super.initState();
    configureBoard();
  }

  configureBoard() {
    dotsHorizontal = 5;
    dotsVertical = 5;

    dots = {};
    for (int x = 0; x < dotsHorizontal; x++) {
      for (int y = 0; y < dotsVertical; y++) {
        dots.add(Dot((x, y)));
      }
    }

    boxes = {};
    lines = {};
    final List<Dot> boxDots = [];
    for (int x = 0; x < dotsHorizontal - 1; x++) {
      for (int y = 0; y < dotsVertical - 1; y++) {
        boxDots.clear();
        Box box = Box((x, y));

        var nw = dots.where((dot) => dot.position == (x, y)).single;
        var ne = dots.where((dot) => dot.position == (x + 1, y)).single;
        var se = dots.where((dot) => dot.position == (x + 1, y + 1)).single;
        var sw = dots.where((dot) => dot.position == (x, y + 1)).single;

        boxDots.add(nw);
        boxDots.add(ne);
        boxDots.add(se);
        boxDots.add(sw);

        var n = Line(nw.position, ne.position);
        var e = Line(ne.position, se.position);
        var s = Line(sw.position, se.position);
        var w = Line(nw.position, sw.position);

        lines.add(n);
        lines.add(e);
        lines.add(s);
        lines.add(w);

        box.lines[lines.where((line) => line == n).single] = Direction.n;
        box.lines[lines.where((line) => line == e).single] = Direction.e;
        box.lines[lines.where((line) => line == s).single] = Direction.s;
        box.lines[lines.where((line) => line == w).single] = Direction.w;

        boxes.add(box);
      }
    }

    resetGame();
  }

  resetGame() {
    showRestartConfirmation = false;
    gameStarted = false;

    for (final line in lines) {
      line.drawer = Who.nobody;
    }
    for (final box in boxes) {
      box.closer = Who.nobody;
    }
    for (final player in players.values) {
      player.score = 0;
    }

    currentPlayer = Who.p1;
    winnerText = "";

    setState(() {});
  }

  // For testing, not actual game-play:
  Future<void> closeSomeBoxes({int percentage = 100}) async {
    var player = Who.p1;
    var shuffled = lines.toList()..shuffle();
    for (final line in shuffled.take((shuffled.length * percentage / 100).ceil())) {
      line.drawer = player;
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {});

      // TODO: Optimize this (make the mapping two-way?)
      for (final box in boxes.where((box) => box.lines.containsKey(line))) {
        if (box.isClosed()) {
          box.closer = player;
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() {});
        }
      }

      // Switch players:
      if (player == Who.p1) {
        player = Who.p2;
      } else {
        player = Who.p1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      late final int quarterTurns;
      quarterTurns = constraints.maxWidth < constraints.maxHeight ? 3 : 0;

      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/image.jpg'), // Replace with your image asset
                fit: BoxFit.cover, // You can adjust the fit as needed
              ),
            ),
          ),
          Column(
            children: [

              SizedBox(height: 75),


              Text('DOTS AND BOXES',style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                fontFamily: 'homework',
              ),),





              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                    children: [
                      SizedBox(width: 30,),
                      Column(children: [

                        for (final player in players.values.skip(1))
                          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text("${player.name}: ",
                                // TODO: Include an assets-based font and set a global text style in main.dart:
                                style: TextStyle(
                                    fontFamily: "kid",
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: player.color)),
                            const SizedBox(height: 20),
                            Text(('{:3d}'.format(player.score)),
                                style: TextStyle(
                                  fontSize: 25,
                                    fontFamily: "kid",
                                    fontWeight: FontWeight.bold,
                                    color: player.color)),
                          ]),
                      ]),

                  SizedBox(width: 80,),
                  // IconButton(
                  //   icon: const Icon(Icons.restart_alt, semanticLabel: 'restart'),
                  //   tooltip: 'Restart game',
                  //
                  //   onPressed: () {
                  //     showRestartConfirmation = true;
                  //     setState(() {});
                  //   },
                  // ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red, // Set the background color
                        ),
                        onPressed: () {
                          showRestartConfirmation = true;
                          setState(() {});
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restart_alt), // Replace with the restart icon you want
                            SizedBox(width: 8), // Adjust the width as needed for spacing
                            Text("Restart"),

                          ],
                        ),
                      ),


                      const SizedBox(width: 20),

                ]),
              ),
              Expanded(
                child: RotatedBox(
                  quarterTurns: quarterTurns,
                  child: Stack(children: [
                    DrawBoxes(boxes),
                    DrawDots(dots, onLineRequested: onLineRequested),
                  ]),
                ),
              ),

            ],
          ),
          if (winnerText.isNotEmpty)
            AlertDialog(
              title: const Text('Game Over'),
              content: Text(winnerText),
              actions: <Widget>[
                TextButton(onPressed: () => resetGame(), child: const Text('OK')),
              ],
            ),
          if (showRestartConfirmation)
            AlertDialog(
              title: const Text('Confirm game restart'),
              content: const Text("Restart game now?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    showRestartConfirmation = false;
                    endGame();
                  },
                  child: const Text('Yes, restart game'),
                ),
                TextButton(
                  onPressed: () {
                    showRestartConfirmation = false;
                    setState(() {});
                  },
                  child: const Text('No, continue game'),
                ),
              ],
            ),
        ],
      );
    });
  }

  onLineRequested(Dot src, Dot dest) {
    switch (lines.where((x) => x == Line(src.position, dest.position)).toList()) {
      case []:
        debugPrint("Line is not valid");

      case [Line line]:
        line.drawer = currentPlayer;
        gameStarted = true;
        var closedABox = false;

        for (final box in boxes.where((box) => box.lines.containsKey(line))) {
          if (box.isClosed()) {
            box.closer = currentPlayer;
            closedABox = true;
            players[currentPlayer]?.score =
                boxes.where((box) => box.closer == currentPlayer).length;
          }
        }

        if (boxes.where((box) => box.closer == Who.nobody).isEmpty) {
          endGame();
        } else if (!closedABox) {
          switchPlayer();
        }
    }

    setState(() {});
  }

  switchPlayer() {
    if (currentPlayer == Who.p1) {
      currentPlayer = Who.p2;
    } else {
      currentPlayer = Who.p1;
    }
  }

  endGame() {
    var hiScore = -1;
    var tie = false;
    var winner = Who.nobody.name;

    for (final player in players.values.skip(1)) {
      if (player.score == hiScore) {
        tie = true;
      } else if (player.score > hiScore) {
        tie = false;
        winner = player.name;
        hiScore = player.score;
      }
    }

    if (tie) {
      FlameAudio.play("aw.wav");
      winnerText = "The game ended in a tie.";
    } else {
      FlameAudio.play("yay.mp3");
      winnerText = "$winner wins with $hiScore boxes closed!";
    }
    debugPrint(winnerText);

    setState(() {});
  }
}
