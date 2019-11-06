/// Represents the state of a game, as received from the game server.
class SCGameState {
    // MARK: - Properties

    /// The color of the player starting the game.
    let startPlayer: SCPlayerColor

    // MARK: - Initializers

    /// Creates a new game state with the given start player.
    ///
    /// - Parameter startPlayer: The player starting the game.
    init(startPlayer: SCPlayerColor) {
        self.startPlayer = startPlayer
    }

    /// Creates a new game state by copying the given game state.
    ///
    /// - Parameter gameState: The game state to copy.
    init(withGameState gameState: SCGameState) {
        self.startPlayer = gameState.startPlayer
    }

    // MARK: - Methods

    func setField(field: SCField) { }

    /// Returns the possible moves of the current player.
    ///
    /// - Returns: The array of possible moves.
    func possibleMoves() -> [SCMove] {
        [SCMove()]
    }

    /// Performs the given move on the game board.
    ///
    /// - Returns: `true` if the move could be performed; otherwise, `false`.
    func performMove(move: SCMove) -> Bool {
        print("Move perfomed!")
        return true
    }
}