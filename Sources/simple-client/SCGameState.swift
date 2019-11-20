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
    /// The deployed pieces of the blue player.
    private var deployedBluePieces: [SCPieceType]
    /// The undeployed pieces of the blue player.
    private var undeployedBluePieces: [SCPieceType]
    /// The deployed pieces of the red player.
    private var deployedRedPieces: [SCPieceType]
    /// The undeployed pieces of the red player.
    private var undeployedRedPieces: [SCPieceType]
    /// The stack used to revert the last move.
    private var undoStack = [SCMove?]()

    /// The current round number.
    var round: Int {
        self.turn / 2
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
            let lower = max(0, -x) - SCConstants.shift
            let upper = min(0, -x) + SCConstants.shift

            return (lower...upper).map { SCField(x: x, y: $0) }
        }

        // Initialize the deployed pieces of both players.
        self.deployedBluePieces = []
        self.deployedRedPieces = []

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
        self.deployedBluePieces = gameState.deployedBluePieces
        self.undeployedBluePieces = gameState.undeployedBluePieces
        self.deployedRedPieces = gameState.deployedRedPieces
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
            self.getField(x: x, y: y).state
        }
    }

    /// Accesses the field state of the field with the given cube coordinate.
    ///
    /// - Parameter coordinate: The cube coordinate of the field.
    subscript(coordinate: SCCubeCoordinate) -> SCFieldState {
        get {
            self[coordinate.x, coordinate.y]
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
        let shiftX = x + SCConstants.shift
        return self.board[shiftX][y + min(SCConstants.shift, shiftX)]
    }

    /// Returns the field with the given cube coordinate.
    ///
    /// - Parameter coordinate: The cube coordinate of the field.
    ///
    /// - Returns: The field with the given cube coordinate.
    func getField(coordinate: SCCubeCoordinate) -> SCField {
        self.getField(x: coordinate.x, y: coordinate.y)
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

    /// Returns the field state of the field with the given cube coordinate.
    ///
    /// - Parameter coordinate: The cube coordinate of the field.
    ///
    /// - Returns: The state of the field.
    func getFieldState(coordinate: SCCubeCoordinate) -> SCFieldState {
        self[coordinate]
    }

    /// Replaces the field that has the same cube coordinate as the given field
    /// with the given field.
    ///
    /// - Parameter field: The field to be placed on the game board.
    func setField(field: SCField) {
        let x = field.coordinate.x + SCConstants.shift
        self.board[x][field.coordinate.y + min(SCConstants.shift, x)] = field
    }

    /// Returns the fields owned by the given player.
    ///
    /// - Parameter player: The color of the player to search for on the board.
    ///
    /// - Returns: The array of fields owned by the given player.
    func getFields(ofPlayer player: SCPlayerColor) -> [SCField] {
        self.board.flatMap { $0.filter { $0.isOwned(byPlayer: player) } }
    }

    /// Returns the fields of the insect swarm.
    ///
    /// - Returns: The array of fields of the insect swarm.
    func swarmFields() -> [SCField] {
        self.board.flatMap { $0.filter { $0.hasOwner() } }
    }

    /// Returns the empty fields around the insect swarm.
    ///
    /// - Returns: The array of empty fields around the insect swarm.
    func fieldsAroundSwarm() -> [SCField] {
        Set(self.swarmFields().flatMap {
            $0.coordinate.neighbours().filter { self.isFieldOnBoard(coordinate: $0) }
        }).compactMap {
            let field = self.getField(coordinate: $0)
            return field.isEmpty() ? field : nil
        }
    }

    /// Returns a Boolean value indicating whether the field with the given x-
    /// and y-coordinate is on the game board.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    ///
    /// - Returns: `true` if the field with the given x- and y-coordinate is on
    ///   the game board; otherwise, `false`.
    func isFieldOnBoard(x: Int, y: Int) -> Bool {
        abs(x) <= SCConstants.shift && y >= max(0, -x) - SCConstants.shift && y <= min(0, -x) + SCConstants.shift
    }

    /// Returns a Boolean value indicating whether the field with the given cube
    /// coordinate is on the game board.
    ///
    /// - Parameter coordinate: The cube coordinate of the field.
    ///
    /// - Returns: `true` if the field with the given cube coordinate is on the
    ///   game board; otherwise, `false`.
    func isFieldOnBoard(coordinate: SCCubeCoordinate) -> Bool {
        self.isFieldOnBoard(x: coordinate.x, y: coordinate.y)
    }

    /// Returns the neighbouring fields of the field with the given x- and
    /// y-coordinate.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    ///
    /// - Returns: The array of neighbouring fields. If the given x- or
    ///   y-coordinate is not on the board, `nil` is returned.
    func neighboursOfField(x: Int, y: Int) -> [SCField]? {
        self.neighboursOfField(coordinate: SCCubeCoordinate(x: x, y: y))
    }

    /// Returns the neighbouring fields of the field with the given x- and
    /// y-coordinate which have the given field state.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    ///   - state: The field state to search for on the board.
    ///
    /// - Returns: The array of neighbouring fields with the given field state.
    ///   If the given x- or y-coordinate is not on the board, `nil` is
    ///   returned.
    func neighboursOfField(x: Int, y: Int, withState state: SCFieldState) -> [SCField]? {
        self.neighboursOfField(coordinate: SCCubeCoordinate(x: x, y: y), withState: state)
    }

    /// Returns the neighbouring fields of the field with the given cube
    /// coordinate.
    ///
    /// - Parameter coordinate: The cube coordinate of the field.
    ///
    /// - Returns: The array of neighbouring fields. If the given cube
    ///   coordinate is not on the board, `nil` is returned.
    func neighboursOfField(coordinate: SCCubeCoordinate) -> [SCField]? {
        guard self.isFieldOnBoard(coordinate: coordinate) else {
            return nil
        }

        return coordinate.neighbours().compactMap {
            self.isFieldOnBoard(coordinate: $0) ? self.getField(coordinate: $0) : nil
        }
    }

    /// Returns the neighbouring fields of the field with the given cube
    /// coordinate which have the given field state.
    ///
    /// - Parameters:
    ///   - coordinate: The cube coordinate of the field.
    ///   - state: The field state to search for on the board.
    ///
    /// - Returns: The array of neighbouring fields with the given field state.
    ///   If the given cube coordinate is not on the board, `nil` is returned.
    func neighboursOfField(coordinate: SCCubeCoordinate, withState state: SCFieldState) -> [SCField]? {
        self.neighboursOfField(coordinate: coordinate)?.filter { $0.state == state }
    }

    /// Returns the deployed pieces of the given player.
    ///
    /// - Parameter player: The color of the player.
    ///
    /// - Returns: The array of deployed pieces of the given player.
    func deployedPieces(ofPlayer player: SCPlayerColor) -> [SCPieceType] {
        player == .blue ? self.deployedBluePieces : self.deployedRedPieces
    }

    /// Returns the undeployed pieces of the given player.
    ///
    /// - Parameter player: The color of the player.
    ///
    /// - Returns: The array of undeployed pieces of the given player.
    func undeployedPieces(ofPlayer player: SCPlayerColor) -> [SCPieceType] {
        player == .blue ? self.undeployedBluePieces : self.undeployedRedPieces
    }

    /// Returns the field of the bee of the given player.
    ///
    /// - Parameter player: The color of the player.
    ///
    /// - Returns: The field of the bee. If the player has not set the bee yet,
    ///   `nil` is returned.
    func fieldOfBee(ofPlayer player: SCPlayerColor) -> SCField? {
        self.board.joined().first { $0.pieces.contains { $0.type == .bee && $0.owner == player } }
    }

    /// Returns a Boolean value indicating whether the bee of the given player
    /// is blocked.
    ///
    /// - Parameter player: The color of the player.
    ///
    /// - Returns: `true` if the bee of the given player is blocked; otherwise,
    ///   `false`.
    func isBeeBlocked(ofPlayer player: SCPlayerColor) -> Bool {
        guard let coordinate = self.fieldOfBee(ofPlayer: player)?.coordinate else {
            return false
        }

        return self.neighboursOfField(coordinate: coordinate, withState: .empty)!.isEmpty
    }

    /// Returns the possible drag moves of the current player.
    ///
    /// - Returns: The array of possible drag moves.
    func possibleDragMoves() -> [SCMove] { [] }

    /// Returns the possible set moves of the current player.
    ///
    /// - Returns: The array of possible set moves.
    func possibleSetMoves() -> [SCMove] {
        let opponentPlayer = self.currentPlayer.opponentColor
        var coordinates = [SCCubeCoordinate]()

        if self.deployedPieces(ofPlayer: self.currentPlayer).isEmpty {
            if self.turn == 0 {
                coordinates = self.board.joined().compactMap { $0.isEmpty() ? $0.coordinate : nil }
            } else {
                coordinates = self.fieldsAroundSwarm().map { $0.coordinate }
            }
        } else {
            coordinates = Set(self.getFields(ofPlayer: self.currentPlayer).flatMap {
                self.neighboursOfField(coordinate: $0.coordinate, withState: .empty)!.map { $0.coordinate }
            }).filter {
                self.neighboursOfField(coordinate: $0)!.allSatisfy {
                    guard let owner = $0.owner else {
                        return true
                    }

                    return owner != opponentPlayer
                }
            }
        }

        let undeployedPieces = Set(self.undeployedPieces(ofPlayer: self.currentPlayer))
        let pieces = undeployedPieces.contains(.bee) && self.round > 2 ? [.bee] : undeployedPieces

        return coordinates.flatMap { coordinate in
            pieces.map { SCMove(piece: SCPiece(owner: self.currentPlayer, type: $0), destination: coordinate) }
        }
    }

    /// Returns the possible moves of the current player.
    ///
    /// - Returns: The array of possible moves.
    func possibleMoves() -> [SCMove] {
        let moves = self.possibleSetMoves() + self.possibleDragMoves()

        return moves.isEmpty ? [SCMove()] : moves
    }

    /// Performs the given move on the game board.
    ///
    /// - Parameter move: The move to be performed.
    ///
    /// - Returns: `true` if the move could be performed; otherwise, `false`.
    func performMove(move: SCMove) -> Bool {
        // TODO: Validate the move.

        self.undoStack.append(self.lastMove)

        switch move.type {
            case .dragMove:
                let start = move.start!
                let startX = start.x + SCConstants.shift
                _ = self.board[startX][start.y + min(SCConstants.shift, startX)].pieces.popLast()

                let dest = move.destination!
                let destX = dest.x + SCConstants.shift
                self.board[destX][dest.y + min(SCConstants.shift, destX)].pieces.append(move.piece!)
            case .setMove:
                let dest = move.destination!
                let destX = dest.x + SCConstants.shift
                let piece = move.piece!
                self.board[destX][dest.y + min(SCConstants.shift, destX)].pieces.append(piece)

                switch self.currentPlayer {
                    case .blue:
                        self.deployedBluePieces.append(piece.type)
                        self.undeployedBluePieces.removeFirst(of: piece.type)
                    case .red:
                        self.deployedRedPieces.append(piece.type)
                        self.undeployedRedPieces.removeFirst(of: piece.type)
                }
            default:
                break
        }

        self.turn += 1
        self.currentPlayer.switchColor()
        self.lastMove = move

        return true
    }

    /// Reverts the last move performed on the game board.
    func undoLastMove() {
        if let lastMove = self.lastMove,
           let oldLastMove = self.undoStack.popLast() {
            self.lastMove = oldLastMove
            self.currentPlayer.switchColor()
            self.turn -= 1

            switch lastMove.type {
                case .dragMove:
                    let start = lastMove.start!
                    let startX = start.x + SCConstants.shift
                    self.board[startX][start.y + min(SCConstants.shift, startX)].pieces.append(lastMove.piece!)

                    let dest = lastMove.destination!
                    let destX = dest.x + SCConstants.shift
                    _ = self.board[destX][dest.y + min(SCConstants.shift, destX)].pieces.popLast()
                case .setMove:
                    let dest = lastMove.destination!
                    let destX = dest.x + SCConstants.shift
                    _ = self.board[destX][dest.y + min(SCConstants.shift, destX)].pieces.popLast()

                    let piece = lastMove.piece!.type
                    switch self.currentPlayer {
                        case .blue:
                            self.deployedBluePieces.removeFirst(of: piece)
                            self.undeployedBluePieces.append(piece)
                        case .red:
                            self.deployedRedPieces.removeFirst(of: piece)
                            self.undeployedRedPieces.append(piece)
                    }
                default:
                    break
            }
        }
    }

    // MARK: - CustomStringConvertible

    var description: String {
        (-SCConstants.shift...SCConstants.shift).reduce(into: "") { res, z in
            let lower = max(0, -z) - SCConstants.shift
            let upper = min(0, -z) + SCConstants.shift

            res += (lower...upper).map {
                switch self[$0, -$0 - z] {
                    case .red:
                        return "R"
                    case .blue:
                        return "B"
                    case .obstructed:
                        return "X"
                    case .empty:
                        return "-"
                }
            } + "\n"
        }
    }
}