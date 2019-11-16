/// Represents the state of a game, as received from the game server.
class SCGameState: CustomStringConvertible {
    // MARK: - Properties

    /// The color of the player starting the game.
    let startPlayer: SCPlayerColor
    /// The color of the current player.
    private(set) var currentPlayer: SCPlayerColor
    /// The current turn number.
    private(set) var turn = 0
    /// The last move that has been performed.
    private(set) var lastMove: SCMove?
    /// The two-dimensional array of fields representing the game board.
    private(set) var board: [[SCField]]
    /// The undeployed pieces of the blue player.
    private(set) var undeployedBluePieces: [SCPieceType]
    /// The undeployed pieces of the red player.
    private(set) var undeployedRedPieces: [SCPieceType]
    /// The stack used to revert the last move.
    private var undoStack = [SCMove?]()

    /// The current round number.
    var round: Int {
        self.turn / 2 + 1
    }

    // MARK: - Initializers

    /// Creates a new game state with the given start player.
    ///
    /// - Parameter startPlayer: The player starting the game.
    init(startPlayer: SCPlayerColor) {
        self.startPlayer = startPlayer
        self.currentPlayer = startPlayer

        // Initialize the board with empty fields.
        self.board = (-SCConstants.shift...SCConstants.shift).map { x in
            let lower = max(-SCConstants.shift, -x - SCConstants.shift)
            let upper = min(SCConstants.shift, -x + SCConstants.shift)

            return (lower...upper).map { SCField(coordinate: SCCubeCoordinate(x: x, y: $0)) }
        }

        // Initialize the undeployed pieces of both players.
        let startingPieces = SCConstants.startingPieces.compactMap { SCPieceType(shortDescription: $0) }
        self.undeployedBluePieces = startingPieces
        self.undeployedRedPieces = startingPieces
    }

    /// Creates a new game state by copying the given game state.
    ///
    /// - Parameter gameState: The game state to copy.
    init(withGameState gameState: SCGameState) {
        self.startPlayer = gameState.startPlayer
        self.currentPlayer = gameState.currentPlayer
        self.turn = gameState.turn
        self.lastMove = gameState.lastMove
        self.board = gameState.board
        self.undeployedBluePieces = gameState.undeployedBluePieces
        self.undeployedRedPieces = gameState.undeployedRedPieces
        self.undoStack = gameState.undoStack
    }

    // MARK: - Subscripts

    /// Accesses the field state of the field with the given x- and
    /// y-coordinate.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    subscript(x: Int, y: Int) -> SCFieldState {
        get {
            self.board[x + SCConstants.shift][y + SCConstants.shift].state
        }
    }

    // MARK: - Methods

    /// Returns the field with the given x- and y-coordinate.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    ///
    /// - Returns: The field with the given x- and y-coordinate.
    func getField(x: Int, y: Int) -> SCField {
        self.board[x + SCConstants.shift][y + SCConstants.shift]
    }

    /// Returns the field state of the field with the given x- and y-coordinate.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    ///
    /// - Returns: The state of the field.
    func getFieldState(x: Int, y: Int) -> SCFieldState {
        self[x, y]
    }

    /// Replaces the field that has the same cube coordinate as the given field
    /// with the given field.
    ///
    /// - Parameter field: The field to be placed on the game board.
    func setField(field: SCField) {
        let x = field.coordinate.x + SCConstants.shift
        let y = field.coordinate.y + SCConstants.shift
        self.board[x][y] = field
    }

    /// Returns the fields owned by the given player.
    ///
    /// - Parameter player: The color of the player to search for on the board.
    ///
    /// - Returns: The array of fields owned by the given player.
    func getFields(ofPlayer player: SCPlayerColor) -> [SCField] {
        self.board.flatMap { $0.filter { $0.isOwned(byPlayer: player) } }
    }

    /// Returns the possible moves of the current player.
    ///
    /// - Returns: The array of possible moves.
    func possibleMoves() -> [SCMove] { [] }

    /// Performs the given move on the game board.
    ///
    /// - Returns: `true` if the move could be performed; otherwise, `false`.
    func performMove(move: SCMove) -> Bool { false }

    // MARK: - CustomStringConvertible

    var description: String { "SCGameState" }
}