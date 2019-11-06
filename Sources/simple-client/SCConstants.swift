/// Contains some constants that are used within this package.
struct SCConstants {
    // MARK: - Properties

    /// The size of the game board.
    static let boardSize = 11
    /// The game identifier used in the communication with the game server.
    static let gameIdentifier = "swc_2020_hive"
    /// The maximum number of rounds per game.
    static let roundLimit = 30
    /// The radius of the game board.
    static let shift = (boardSize - 1) / 2
    /// The pieces of each player at the beginning of a game.
    static let startingPieces = "QSSSGGBBAAA"
    /// The maximum number of turns per game.
    static let turnLimit = roundLimit * 2

    // MARK: - Initializers

    // Hide the initializer to not allow instances of this struct.
    private init() { }
}