import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';

enum Player { X, O }

class TicTacToe extends StatefulWidget {
  final String name1;
  final String name2;
  final bool isSinglePlayer;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String difficulty;

  const TicTacToe({
    super.key,
    required this.name1,
    required this.name2,
    required this.isSinglePlayer,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.difficulty,
  });

  @override
  State<TicTacToe> createState() => _TicTacToeState();
}

class _TicTacToeState extends State<TicTacToe> {
  List<String> board = List.filled(9, '');
  Player currentPlayer = Player.X;
  String output = '';
  bool gameOver = false;
  List<int> winningTiles = [];
  final AudioPlayer player = AudioPlayer();
  bool? hasVibration;
  Map<int, int> userMovePatterns = {};

  @override
  void initState() {
    super.initState();
    output = "${widget.name1}'s Turn";
    _checkVibrationSupport();
    _loadUserPatterns();
  }

  void _checkVibrationSupport() async {
    hasVibration = await Vibration.hasVibrator();
  }

  void _playSound() {
    if (widget.soundEnabled) {
      player.play(AssetSource('tap.wav'));
    }
  }

  void _onTileTap(int index) {
    if (board[index] != '' || gameOver) return;

    setState(() {
      board[index] = currentPlayer == Player.X ? 'X' : 'O';
      _trackUserMove(index);
      _playSound();
      _checkGameState();
      if (widget.isSinglePlayer && !gameOver && currentPlayer == Player.O) {
        Future.delayed(const Duration(milliseconds: 500), _aiMove);
      }
    });
  }

  void _aiMove() {
    if (gameOver) return;
    int aiIndex = _findBestMove();
    if (aiIndex != -1) {
      setState(() {
        board[aiIndex] = 'O';
        _checkGameState();
      });
    }
  }

  int _findBestMove() {
    if (widget.difficulty == "Unfair" || widget.difficulty == "Hard") {
      return _minimax(List.from(board), 0, true, -1000, 1000).index;
    } else {
      return _machineLearningMove();
    }
  }

  bool _checkWinnerMinimax(List<String> board, String player) {
  List<List<int>> winPatterns = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
    [0, 4, 8], [2, 4, 6]             // Diagonals
  ];
  for (var pattern in winPatterns) {
    if (pattern.every((i) => board[i] == player)) {
      return true;
    }
  }
  return false;
}

 Move _minimax(List<String> newBoard, int depth, bool isMax, int alpha, int beta) {
  if (_checkWinnerMinimax(newBoard, 'O')) return Move(-1, 10 - depth);
  if (_checkWinnerMinimax(newBoard, 'X')) return Move(-1, depth - 10);
  if (!newBoard.contains('')) return Move(-1, 0);

  List<int> availableMoves =
      List.generate(9, (i) => i).where((i) => newBoard[i] == '').toList();

  Move bestMove = isMax ? Move(-1, -1000) : Move(-1, 1000);

  for (int move in availableMoves) {
    newBoard[move] = isMax ? 'O' : 'X';
    int score = _minimax(List.from(newBoard), depth + 1, !isMax, alpha, beta).score;
    newBoard[move] = '';

    if (isMax) {
      if (score > bestMove.score) bestMove = Move(move, score);
      alpha = max(alpha, bestMove.score);
    } else {
      if (score < bestMove.score) bestMove = Move(move, score);
      beta = min(beta, bestMove.score);
    }
    if (beta <= alpha) break;
  }

  return bestMove;
}
  int _machineLearningMove() {
    List<int> availableMoves =
        List.generate(9, (i) => i).where((i) => board[i] == '').toList();
    if (availableMoves.isEmpty) return -1;

    // Check for a winning move for AI
    for (int move in availableMoves) {
      board[move] = 'O';
      if (_checkWinner('O')) {
        board[move] = '';
        return move;
      }
      board[move] = '';
    }

    // Check for a blocking move (player is about to win)
    for (int move in availableMoves) {
      board[move] = 'X';
      if (_checkWinner('X')) {
        board[move] = '';
        return move;
      }
      board[move] = '';
    }

    // Sort moves based on user patterns
    availableMoves.sort((a, b) =>
        (userMovePatterns[b] ?? 0).compareTo(userMovePatterns[a] ?? 0));

    return availableMoves.first;
  }

  void _trackUserMove(int index) async {
  final prefs = await SharedPreferences.getInstance();
  
  // Convert keys to strings before saving
  Map<String, int> stringKeyMap = userMovePatterns.map((key, value) => MapEntry(key.toString(), value));
  
  prefs.setString('movePatterns', jsonEncode(stringKeyMap));
}


  void _loadUserPatterns() async {
  final prefs = await SharedPreferences.getInstance();
  String? storedPatterns = prefs.getString('movePatterns');
  
  if (storedPatterns != null) {
    Map<String, dynamic> decoded = jsonDecode(storedPatterns);
    
    // Convert string keys back to integers
    userMovePatterns = decoded.map((key, value) => MapEntry(int.parse(key), value as int));
  }
}


  void _checkGameState() {
    if (_checkWinner('X')) {
      _handleWin(widget.name1);
    } else if (_checkWinner('O')) {
      _handleWin(widget.name2);
    } else if (!board.contains('')) {
      setState(() {
        output = "It's a Draw!";
        gameOver = true;
      });
    } else {
      setState(() {
        currentPlayer = currentPlayer == Player.X ? Player.O : Player.X;
        output = "${currentPlayer == Player.X ? widget.name1 : widget.name2}'s Turn";
      });
    }
  }

  void _handleWin(String winner) {
    setState(() {
      output = "$winner Wins!";
      gameOver = true;
    });
    if (widget.vibrationEnabled && hasVibration!) {
      Vibration.vibrate(duration: 300);
    }
  }

  bool _checkWinner(String player) {
    List<List<int>> winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];
    for (var pattern in winPatterns) {
      if (pattern.every((i) => board[i] == player)) {
        winningTiles = pattern;
        return true;
      }
    }
    return false;
  }

  void _resetGame() {
    setState(() {
      board = List.filled(9, '');
      gameOver = false;
      winningTiles = [];
      currentPlayer = Player.X;
      output = "${widget.name1}'s Turn";
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: const Text("Tic Tac Toe", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Game Status
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade800.withOpacity(0.6),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.6),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              output,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Tic Tac Toe Board
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                bool isWinningTile = winningTiles.contains(index);
                String value = board[index];
                bool isFilled = value.isNotEmpty;

                return GestureDetector(
                  onTap: () => _onTileTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isWinningTile
                          ? Colors.greenAccent.withOpacity(0.8)
                          : isFilled
                              ? Colors.grey.shade900
                              : Colors.transparent, // Empty tiles stay transparent
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: isWinningTile
                          ? [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.8),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ]
                          : isFilled
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                      border: Border.all(
                        color: isFilled ? Colors.white.withOpacity(0.5) : Colors.grey.shade700,
                        width: isFilled ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: AnimatedScale(
                        scale: isFilled ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: value == 'X' ? Colors.cyanAccent : Colors.pinkAccent,
                            shadows: isWinningTile
                                ? [
                                    const Shadow(color: Colors.white, blurRadius: 15),
                                  ]
                                : [],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Restart Button
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              shadowColor: Colors.redAccent.withOpacity(0.5),
              elevation: 10,
            ),
            child: const Text(
              "Restart Game",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class Move {
  int index;
  int score;

  Move(this.index, this.score);
}