/// The type of a move.
enum SCMoveType: String, CaseIterable, CustomStringConvertible {
    /// An existing piece on the game board is moved to a new field.
    case dragMove = "DRAGMOVE"
    /// A piece is placed on the game board.
    case setMove = "SETMOVE"
    /// No piece is moved or placed on the game board.
    case skipMove = "SKIPMOVE"

    // MARK: - CustomStringConvertible

    var description: String {
        self.rawValue
    }
}