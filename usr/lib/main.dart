import 'package:flutter/material.dart';
import 'chess_logic.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '快乐国际象棋',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default font
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ChessGamePage(),
      },
    );
  }
}

class ChessGamePage extends StatefulWidget {
  const ChessGamePage({super.key});

  @override
  State<ChessGamePage> createState() => _ChessGamePageState();
}

class _ChessGamePageState extends State<ChessGamePage> {
  final ChessLogic _game = ChessLogic();
  int? _selectedSquare;
  List<int> _validMoves = [];
  bool _isAiThinking = false;
  String _gameStatus = "该你走啦！"; // "It's your turn!"

  // Colors for the board - Soft and child-friendly
  final Color _lightSquare = const Color(0xFFFFF0C2); // Cream
  final Color _darkSquare = const Color(0xFF81C784);  // Soft Green
  final Color _highlightColor = const Color(0xFF64B5F6).withOpacity(0.6); // Blue highlight
  final Color _validMoveColor = const Color(0xFFFFB74D).withOpacity(0.8); // Orange dots

  void _onSquareTap(int index) async {
    if (_isAiThinking) return;
    if (_game.isKingCaptured(PieceColor.white) || _game.isKingCaptured(PieceColor.black)) return;

    // If tapping a valid move for the selected piece
    if (_selectedSquare != null && _validMoves.contains(index)) {
      setState(() {
        _game.move(_selectedSquare!, index);
        _selectedSquare = null;
        _validMoves = [];
        _gameStatus = "小AI正在思考...";
        _isAiThinking = true;
      });

      // Check win condition
      if (_checkWin()) {
        setState(() => _isAiThinking = false);
        return;
      }

      // AI Turn with delay
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      setState(() {
        bool moved = _game.makeRandomMove();
        _isAiThinking = false;
        if (!moved) {
          _gameStatus = "你赢了！小AI无路可走";
        } else {
          _gameStatus = "该你走啦！";
        }
      });
      
      _checkWin();
      return;
    }

    // Selecting a piece
    if (_game.board[index] != null && _game.board[index]!.color == PieceColor.white) {
      setState(() {
        _selectedSquare = index;
        _validMoves = _game.getLegalMoves(index);
      });
    } else {
      // Tapping empty square or enemy piece without selection
      setState(() {
        _selectedSquare = null;
        _validMoves = [];
      });
    }
  }

  bool _checkWin() {
    if (_game.isKingCaptured(PieceColor.black)) {
      _showWinDialog("太棒了！", "你赢了！你打败了小AI！ 🎉");
      setState(() => _gameStatus = "胜利！");
      return true;
    }
    if (_game.isKingCaptured(PieceColor.white)) {
      _showWinDialog("哎呀！", "小AI赢了。别灰心，再试一次！ 💪");
      setState(() => _gameStatus = "失败");
      return true;
    }
    return false;
  }

  void _showWinDialog(String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 28)),
        content: Text(content, style: const TextStyle(fontSize: 20)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetGame();
            },
            child: const Text("再玩一局", style: TextStyle(fontSize: 20)),
          )
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _game.resetGame();
      _selectedSquare = null;
      _validMoves = [];
      _gameStatus = "该你走啦！";
      _isAiThinking = false;
    });
  }

  void _undoMove() {
    if (_isAiThinking) return;
    setState(() {
      // Undo twice (AI move + Player move) to get back to player turn
      _game.undo(); // Undo AI
      _game.undo(); // Undo Player
      _selectedSquare = null;
      _validMoves = [];
      _gameStatus = "该你走啦！";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Very light yellow background
      appBar: AppBar(
        title: const Text("快乐国际象棋 ♟️"),
        backgroundColor: Colors.orange[300],
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Opponent Area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.smart_toy, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  ),
                  child: Text(
                    _isAiThinking ? "思考中..." : "我是小AI",
                    style: TextStyle(fontSize: 18, color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
          ),

          // Chess Board
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown, width: 8),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ]
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 64,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                      ),
                      itemBuilder: (context, index) {
                        final int row = index ~/ 8;
                        final int col = index % 8;
                        final bool isWhiteSquare = (row + col) % 2 == 0;
                        
                        bool isSelected = _selectedSquare == index;
                        bool isValidMove = _validMoves.contains(index);
                        bool isLastMove = index == _game.lastMoveFrom || index == _game.lastMoveTo;

                        Color bgColor = isWhiteSquare ? _lightSquare : _darkSquare;
                        if (isSelected) bgColor = Colors.orangeAccent.withOpacity(0.5);
                        if (isLastMove && !isSelected) bgColor = _highlightColor;

                        return GestureDetector(
                          onTap: () => _onSquareTap(index),
                          child: Container(
                            color: bgColor,
                            child: Stack(
                              children: [
                                // Piece
                                if (_game.board[index] != null)
                                  Center(
                                    child: Text(
                                      _game.board[index]!.symbol,
                                      style: TextStyle(
                                        fontSize: 32, // Large pieces for kids
                                        color: _game.board[index]!.color == PieceColor.white 
                                            ? Colors.black 
                                            : Colors.black, // Unicode pieces are usually black/white filled, but we can just use black text for high contrast or style them.
                                        // Actually, standard unicode chess pieces are:
                                        // White pieces: ♔♕♖♗♘♙ (Outlined)
                                        // Black pieces: ♚♛♜♝♞♟ (Filled)
                                        // We can render them all in Black color, and the glyph itself distinguishes color.
                                      ),
                                    ),
                                  ),
                                
                                // Valid Move Indicator
                                if (isValidMove)
                                  Center(
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _game.board[index] == null 
                                            ? _validMoveColor 
                                            : Colors.red.withOpacity(0.7), // Red for capture
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Status Message
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _gameStatus,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
          ),

          // Player Controls
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGameButton(
                  icon: Icons.refresh,
                  label: "重来",
                  color: Colors.redAccent,
                  onTap: _resetGame,
                ),
                _buildGameButton(
                  icon: Icons.undo,
                  label: "悔棋",
                  color: Colors.blueAccent,
                  onTap: _undoMove,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGameButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
