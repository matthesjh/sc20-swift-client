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

    // MARK: - Methods

    /// Returns the possible moves of the current player.
    ///
    /// - Returns: The array of possible moves.
    func possibleMoves() -> [SCMove] {
        [SCMove()]
    }
}