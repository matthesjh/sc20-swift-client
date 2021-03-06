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
    private(set) var deployedBluePieces: [SCPieceType]
    /// The undeployed pieces of the blue player.
    private(set) var undeployedBluePieces: [SCPieceType]
    /// The deployed pieces of the red player.
    private(set) var deployedRedPieces: [SCPieceType]
    /// The undeployed pieces of the red player.
    private(set) var undeployedRedPieces: [SCPieceType]
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

        // Initialize the game board with empty fields.
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
    /// - Parameter player: The color of the player to search for on the game
    ///   board.
    ///
    /// - Returns: The array of fields owned by the given player.
    func getFields(ofPlayer player: SCPlayerColor) -> [SCField] {
        self.board.joined().filter { $0.isOwned(byPlayer: player) }
    }

    /// Returns the fields with the given field state.
    ///
    /// - Parameter state: The field state to search for on the game board.
    ///
    /// - Returns: The array of fields with the given field state.
    func getFields(withState state: SCFieldState) -> [SCField] {
        self.board.joined().filter { $0.state == state }
    }

    /// Returns the fields that are obstructed with a blackberry.
    ///
    /// - Returns: The array of fields that are obstructed with a blackberry.
    func obstructedFields() -> [SCField] {
        self.board.joined().filter { $0.obstructed }
    }

    /// Returns the fields of the insect swarm.
    ///
    /// - Returns: The array of fields of the insect swarm.
    func swarmFields() -> [SCField] {
        self.board.joined().filter { $0.hasOwner() }
    }

    /// Returns the cube coordinates of the fields of the insect swarm.
    ///
    /// - Returns: The array of cube coordinates of the fields of the insect
    ///   swarm.
    func swarmCoordinates() -> [SCCubeCoordinate] {
        self.board.joined().compactMap { $0.hasOwner() ? $0.coordinate : nil }
    }

    /// Returns the empty fields around the insect swarm.
    ///
    /// - Returns: The array of empty fields around the insect swarm.
    func fieldsAroundSwarm() -> [SCField] {
        Set(self.swarmCoordinates().flatMap {
            $0.neighbours().filter(self.isFieldOnBoard)
        }).compactMap {
            let field = self.getField(coordinate: $0)
            return field.isEmpty() ? field : nil
        }
    }

    /// Returns the cube coordinates of the empty fields around the insect
    /// swarm.
    ///
    /// - Returns: The array of cube coordinates of the empty fields around the
    ///   insect swarm.
    func coordinatesAroundSwarm() -> [SCCubeCoordinate] {
        Set(self.swarmCoordinates().flatMap {
            $0.neighbours().filter(self.isFieldOnBoard)
        }).filter { self[$0] == .empty }
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
    ///   y-coordinate is not on the game board, `nil` is returned.
    func neighboursOfField(x: Int, y: Int) -> [SCField]? {
        self.neighboursOfField(coordinate: SCCubeCoordinate(x: x, y: y))
    }

    /// Returns the neighbouring fields of the field with the given x- and
    /// y-coordinate which have the given field state.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    ///   - state: The field state to search for on the game board.
    ///
    /// - Returns: The array of neighbouring fields with the given field state.
    ///   If the given x- or y-coordinate is not on the game board, `nil` is
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
    ///   coordinate is not on the game board, `nil` is returned.
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
    ///   - state: The field state to search for on the game board.
    ///
    /// - Returns: The array of neighbouring fields with the given field state.
    ///   If the given cube coordinate is not on the game board, `nil` is
    ///   returned.
    func neighboursOfField(coordinate: SCCubeCoordinate, withState state: SCFieldState) -> [SCField]? {
        self.neighboursOfField(coordinate: coordinate)?.filter { $0.state == state }
    }

    /// Returns the accessible neighbours of the field with the given cube
    /// coordinate.
    ///
    /// - Parameter coordinate: The cube coordinate of the field.
    ///
    /// - Returns: The array of accessible neighbours.
    func accessibleNeighbours(fromCoordinate coordinate: SCCubeCoordinate) -> [SCCubeCoordinate] {
        coordinate.neighbours().filter {
            self.isFieldOnBoard(coordinate: $0)
                && self[$0] == .empty
                && self.canMove(fromCoordinate: coordinate, toCoordinate: $0)
        }
    }

    /// Returns a Boolean value indicating whether a piece can be moved from the
    /// given start field to the given destination field.
    ///
    /// Both fields must be neighbours.
    ///
    /// - Parameters:
    ///   - start: The cube coordinate of the start field.
    ///   - destination: The cube coordinate of the destination field.
    ///
    /// - Returns: `true`, if the piece can be moved; otherwise, `false`.
    private func canMove(fromCoordinate start: SCCubeCoordinate, toCoordinate destination: SCCubeCoordinate) -> Bool {
        let neighbours = start.neighbours(withCoordinate: destination).filter(self.isFieldOnBoard)

        return neighbours.count { self[$0] != .empty } == 1 && neighbours.count { self.getField(coordinate: $0).hasOwner() } == 1
    }

    /// Returns the next empty field in the given direction starting at the
    /// given field.
    ///
    /// - Parameters:
    ///   - direction: The direction to use.
    ///   - coordinate: The cube coordinate of the start field.
    ///
    /// - Returns: The next empty field on the game board. If no empty field is
    ///   found on the game board or an obstructed one is discovered, `nil` is
    ///   returned.
    func emptyField(inDirection direction: SCDirection, fromCoordinate coordinate: SCCubeCoordinate) -> SCField? {
        var coord = coordinate

        repeat {
            coord = coord.coordinate(inDirection: direction)

            guard self.isFieldOnBoard(coordinate: coord) && self[coord] != .obstructed else {
                return nil
            }
        } while self[coord] != .empty

        return self.getField(coordinate: coord)
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
    func possibleDragMoves() -> [SCMove] {
        guard self.deployedPieces(ofPlayer: self.currentPlayer).contains(.bee) else {
            return []
        }

        return self.getFields(ofPlayer: self.currentPlayer).flatMap { field -> [SCMove] in
            let x = field.coordinate.x + SCConstants.shift
            let y = field.coordinate.y + min(SCConstants.shift, x)
            let piece = self.board[x][y].pieces.removeLast()

            defer {
                self.board[x][y].pieces.append(piece)
            }

            var targets = [SCCubeCoordinate]()

            switch field.pieces.last!.type {
                case .ant:
                    targets = self.antMoves(fromCoordinate: field.coordinate)
                case .bee:
                    targets = self.beeMoves(fromCoordinate: field.coordinate)
                case .beetle:
                    targets = self.beetleMoves(fromCoordinate: field.coordinate)
                case .grasshopper:
                    targets = self.grasshopperMoves(fromCoordinate: field.coordinate)
                case .spider:
                    targets = self.spiderMoves(fromCoordinate: field.coordinate)
            }

            return self.isSwarmConnected() ? targets.map { SCMove(start: field.coordinate, destination: $0) } : []
        }
    }

    /// Returns the possible move destinations for an ant at the given field.
    ///
    /// - Parameter coordinate: The cube coordinate of the field.
    ///
    /// - Returns: The array of possible move destinations.
    private func antMoves(fromCoordinate coordinate: SCCubeCoordinate) -> [SCCubeCoordinate] {
        var visited = [coordinate]
        var i = 0

        while i < visited.count {
            visited += self.accessibleNeighbours(fromCoordinate: visited[i]).filter {
                !visited.contains($0)
            }
            i += 1
        }
        _ = visited.removeFirst()

        return visited
    }

    /// Returns the possible move destinations for a bee at the given field.
    ///
    /// - Parameter coordinate: The cube coordinate of the field.
    ///
    /// - Returns: The array of possible move destinations.
    private func beeMoves(fromCoordinate coordinate: SCCubeCoordinate) -> [SCCubeCoordinate] {
        self.accessibleNeighbours(fromCoordinate: coordinate)
    }

    /// Returns the possible move destinations for a bettle at the given field.
    ///
    /// - Parameter coordinate: The cube coordinate of the field.
    ///
    /// - Returns: The array of possible move destinations.
    private func beetleMoves(fromCoordinate coordinate: SCCubeCoordinate) -> [SCCubeCoordinate] {
        coordinate.neighbours().filter {
            guard self.isFieldOnBoard(coordinate: $0) else {
                return false
            }

            let field = self.getField(coordinate: $0)
            return field.hasOwner() || (field.isEmpty() && self.canMove(fromCoordinate: coordinate, toCoordinate: $0))
        }
    }

    /// Returns the possible move destinations for a grasshopper at the given
    /// field.
    ///
    /// - Parameter coordinate: The cube coordinate of the field.
    ///
    /// - Returns: The array of possible move destinations.
    private func grasshopperMoves(fromCoordinate coordinate: SCCubeCoordinate) -> [SCCubeCoordinate] {
        coordinate.neighbours().filter {
            self.isFieldOnBoard(coordinate: $0) && self.getField(coordinate: $0).hasOwner()
        }.compactMap {
            self.emptyField(inDirection: coordinate.direction(toCoordinate: $0)!, fromCoordinate: coordinate)?.coordinate
        }
    }

    /// Returns the possible move destinations for a spider at the given field.
    ///
    /// - Parameter coordinate: The cube coordinate of the field.
    ///
    /// - Returns: The array of possible move destinations.
    private func spiderMoves(fromCoordinate coordinate: SCCubeCoordinate) -> [SCCubeCoordinate] {
        self.accessibleNeighbours(fromCoordinate: coordinate).flatMap { coord in
            self.accessibleNeighbours(fromCoordinate: coord).filter {
                $0 != coordinate
            }.flatMap {
                self.accessibleNeighbours(fromCoordinate: $0).filter {
                    $0 != coord && $0 != coordinate
                }
            }
        }
    }

    /// Returns the possible set moves of the current player.
    ///
    /// - Returns: The array of possible set moves.
    func possibleSetMoves() -> [SCMove] {
        let opponentPlayer = self.currentPlayer.opponentColor
        var coordinates = [SCCubeCoordinate]()

        if turn == 0 {
            coordinates = self.board.joined().compactMap { $0.isEmpty() ? $0.coordinate : nil }
        } else if turn == 1 {
            coordinates = self.lastMove!.destination!.neighbours().filter {
                self.isFieldOnBoard(coordinate: $0) && self[$0] == .empty
            }
        } else {
            coordinates = Set(self.getFields(ofPlayer: self.currentPlayer).flatMap {
                $0.coordinate.neighbours().filter {
                    self.isFieldOnBoard(coordinate: $0) && self[$0] == .empty
                }
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

    /// Returns a Boolean value indicating whether the pieces on the game board
    /// are connected to a single swarm.
    ///
    /// - Returns: `true` if the pieces on the game board are connected to a
    ///   single swarm; otherwise, `false`.
    func isSwarmConnected() -> Bool {
        var visited = Set<SCCubeCoordinate>()

        func dfs(coord: SCCubeCoordinate) {
            visited.insert(coord)

            coord.neighbours().filter {
                self.isFieldOnBoard(coordinate: $0) && self.getField(coordinate: $0).hasOwner() && !visited.contains($0)
            }.forEach {
                dfs(coord: $0)
            }
        }

        for field in self.board.joined().filter({ $0.hasOwner() }) {
            if visited.isEmpty {
                dfs(coord: field.coordinate)
            } else if !visited.contains(field.coordinate) {
                return false
            }
        }

        return true
    }

    /// Performs the given move on the game board.
    ///
    /// Due to performance reasons the given move is not validated prior to
    /// performing it on the game board.
    ///
    /// - Parameter move: The move to be performed.
    ///
    /// - Returns: `true` if the move could be performed; otherwise, `false`.
    func performMove(move: SCMove) -> Bool {
        self.undoStack.append(self.lastMove)

        switch move.type {
            case .dragMove:
                let start = move.start!
                let startX = start.x + SCConstants.shift
                let piece = self.board[startX][start.y + min(SCConstants.shift, startX)].pieces.removeLast()

                let dest = move.destination!
                let destX = dest.x + SCConstants.shift
                self.board[destX][dest.y + min(SCConstants.shift, destX)].pieces.append(piece)
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
                    let dest = lastMove.destination!
                    let destX = dest.x + SCConstants.shift
                    let piece = self.board[destX][dest.y + min(SCConstants.shift, destX)].pieces.removeLast()

                    let start = lastMove.start!
                    let startX = start.x + SCConstants.shift
                    self.board[startX][start.y + min(SCConstants.shift, startX)].pieces.append(piece)
                case .setMove:
                    let dest = lastMove.destination!
                    let destX = dest.x + SCConstants.shift
                    let piece = self.board[destX][dest.y + min(SCConstants.shift, destX)].pieces.removeLast().type

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