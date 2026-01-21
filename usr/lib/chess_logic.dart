import 'dart:math';

enum PieceType { pawn, rook, knight, bishop, queen, king }
enum PieceColor { white, black }

class ChessPiece {
  final PieceType type;
  final PieceColor color;
  bool hasMoved;

  ChessPiece({required this.type, required this.color, this.hasMoved = false});

  String get symbol {
    if (color == PieceColor.white) {
      switch (type) {
        case PieceType.king: return '♔';
        case PieceType.queen: return '♕';
        case PieceType.rook: return '♖';
        case PieceType.bishop: return '♗';
        case PieceType.knight: return '♘';
        case PieceType.pawn: return '♙';
      }
    } else {
      switch (type) {
        case PieceType.king: return '♚';
        case PieceType.queen: return '♛';
        case PieceType.rook: return '♜';
        case PieceType.bishop: return '♝';
        case PieceType.knight: return '♞';
        case PieceType.pawn: return '♟';
      }
    }
  }
}

class ChessLogic {
  List<ChessPiece?> board = List.filled(64, null);
  PieceColor turn = PieceColor.white;
  List<List<ChessPiece?>> history = [];
  
  // Last move for highlighting
  int lastMoveFrom = -1;
  int lastMoveTo = -1;

  ChessLogic() {
    resetGame();
  }

  void resetGame() {
    board = List.filled(64, null);
    turn = PieceColor.white;
    history.clear();
    lastMoveFrom = -1;
    lastMoveTo = -1;
    _setupBoard();
  }

  void _setupBoard() {
    // Black pieces (Top)
    board[0] = ChessPiece(type: PieceType.rook, color: PieceColor.black);
    board[1] = ChessPiece(type: PieceType.knight, color: PieceColor.black);
    board[2] = ChessPiece(type: PieceType.bishop, color: PieceColor.black);
    board[3] = ChessPiece(type: PieceType.queen, color: PieceColor.black);
    board[4] = ChessPiece(type: PieceType.king, color: PieceColor.black);
    board[5] = ChessPiece(type: PieceType.bishop, color: PieceColor.black);
    board[6] = ChessPiece(type: PieceType.knight, color: PieceColor.black);
    board[7] = ChessPiece(type: PieceType.rook, color: PieceColor.black);
    for (int i = 8; i < 16; i++) {
      board[i] = ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    }

    // White pieces (Bottom)
    board[56] = ChessPiece(type: PieceType.rook, color: PieceColor.white);
    board[57] = ChessPiece(type: PieceType.knight, color: PieceColor.white);
    board[58] = ChessPiece(type: PieceType.bishop, color: PieceColor.white);
    board[59] = ChessPiece(type: PieceType.queen, color: PieceColor.white);
    board[60] = ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[61] = ChessPiece(type: PieceType.bishop, color: PieceColor.white);
    board[62] = ChessPiece(type: PieceType.knight, color: PieceColor.white);
    board[63] = ChessPiece(type: PieceType.rook, color: PieceColor.white);
    for (int i = 48; i < 56; i++) {
      board[i] = ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    }
  }

  bool move(int from, int to) {
    if (board[from] == null) return false;
    if (board[from]!.color != turn) return false;

    List<int> validMoves = getLegalMoves(from);
    if (!validMoves.contains(to)) return false;

    // Save history
    history.add(List.from(board));

    // Execute move
    board[to] = board[from];
    board[from] = null;
    board[to]!.hasMoved = true;

    // Pawn Promotion (Auto promote to Queen for simplicity for kids)
    if (board[to]!.type == PieceType.pawn) {
      int row = to ~/ 8;
      if ((board[to]!.color == PieceColor.white && row == 0) ||
          (board[to]!.color == PieceColor.black && row == 7)) {
        board[to] = ChessPiece(type: PieceType.queen, color: board[to]!.color);
      }
    }

    lastMoveFrom = from;
    lastMoveTo = to;
    turn = turn == PieceColor.white ? PieceColor.black : PieceColor.white;
    return true;
  }

  void undo() {
    if (history.isNotEmpty) {
      board = history.removeLast();
      turn = turn == PieceColor.white ? PieceColor.black : PieceColor.white;
      lastMoveFrom = -1;
      lastMoveTo = -1;
    }
  }

  List<int> getLegalMoves(int index) {
    ChessPiece? piece = board[index];
    if (piece == null) return [];

    List<int> moves = [];
    int row = index ~/ 8;
    int col = index % 8;

    void addIfValid(int r, int c) {
      if (r >= 0 && r < 8 && c >= 0 && c < 8) {
        int targetIndex = r * 8 + c;
        if (board[targetIndex] == null) {
          moves.add(targetIndex);
        } else if (board[targetIndex]!.color != piece.color) {
          moves.add(targetIndex);
        }
      }
    }

    // Helper for sliding pieces (Rook, Bishop, Queen)
    void addDirection(int dr, int dc) {
      for (int i = 1; i < 8; i++) {
        int r = row + dr * i;
        int c = col + dc * i;
        if (r < 0 || r >= 8 || c < 0 || c >= 8) break;
        int targetIndex = r * 8 + c;
        if (board[targetIndex] == null) {
          moves.add(targetIndex);
        } else {
          if (board[targetIndex]!.color != piece.color) {
            moves.add(targetIndex);
          }
          break; // Blocked
        }
      }
    }

    switch (piece.type) {
      case PieceType.pawn:
        int direction = piece.color == PieceColor.white ? -1 : 1;
        // Move forward 1
        int r1 = row + direction;
        if (r1 >= 0 && r1 < 8) {
          if (board[r1 * 8 + col] == null) {
            moves.add(r1 * 8 + col);
            // Move forward 2 (initial)
            if (!piece.hasMoved) {
              int r2 = row + direction * 2;
              if (r2 >= 0 && r2 < 8 && board[r2 * 8 + col] == null) {
                moves.add(r2 * 8 + col);
              }
            }
          }
        }
        // Capture
        for (int dc in [-1, 1]) {
          int r = row + direction;
          int c = col + dc;
          if (r >= 0 && r < 8 && c >= 0 && c < 8) {
            int target = r * 8 + c;
            if (board[target] != null && board[target]!.color != piece.color) {
              moves.add(target);
            }
          }
        }
        break;

      case PieceType.rook:
        addDirection(1, 0);
        addDirection(-1, 0);
        addDirection(0, 1);
        addDirection(0, -1);
        break;

      case PieceType.bishop:
        addDirection(1, 1);
        addDirection(1, -1);
        addDirection(-1, 1);
        addDirection(-1, -1);
        break;

      case PieceType.queen:
        addDirection(1, 0);
        addDirection(-1, 0);
        addDirection(0, 1);
        addDirection(0, -1);
        addDirection(1, 1);
        addDirection(1, -1);
        addDirection(-1, 1);
        addDirection(-1, -1);
        break;

      case PieceType.knight:
        intArrToMoves(row, col, [
          [-2, -1], [-2, 1], [-1, -2], [-1, 2],
          [1, -2], [1, 2], [2, -1], [2, 1]
        ], moves, piece.color);
        break;

      case PieceType.king:
        intArrToMoves(row, col, [
          [-1, -1], [-1, 0], [-1, 1],
          [0, -1],           [0, 1],
          [1, -1],  [1, 0],  [1, 1]
        ], moves, piece.color);
        break;
    }

    return moves;
  }

  void intArrToMoves(int r, int c, List<List<int>> offsets, List<int> moves, PieceColor color) {
    for (var o in offsets) {
      int nr = r + o[0];
      int nc = c + o[1];
      if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8) {
        int target = nr * 8 + nc;
        if (board[target] == null || board[target]!.color != color) {
          moves.add(target);
        }
      }
    }
  }

  // Simple AI: Random legal move
  // Returns true if a move was made
  bool makeRandomMove() {
    List<int> piecesWithMoves = [];
    for (int i = 0; i < 64; i++) {
      if (board[i] != null && board[i]!.color == turn) {
        if (getLegalMoves(i).isNotEmpty) {
          piecesWithMoves.add(i);
        }
      }
    }

    if (piecesWithMoves.isEmpty) return false; // No moves (Checkmate or Stalemate)

    // 1. Try to capture if possible (slightly smarter than totally random)
    for (int from in piecesWithMoves) {
      List<int> moves = getLegalMoves(from);
      for (int to in moves) {
        if (board[to] != null) { // Capture!
           // 30% chance to take the capture immediately to make it slightly interesting
           if (Random().nextDouble() < 0.3) {
             move(from, to);
             return true;
           }
        }
      }
    }

    // 2. Otherwise random
    int from = piecesWithMoves[Random().nextInt(piecesWithMoves.length)];
    List<int> moves = getLegalMoves(from);
    int to = moves[Random().nextInt(moves.length)];
    
    return move(from, to);
  }
  
  bool isKingCaptured(PieceColor color) {
    // Check if King is on board
    for (var piece in board) {
      if (piece != null && piece.type == PieceType.king && piece.color == color) {
        return false;
      }
    }
    return true;
  }
}
