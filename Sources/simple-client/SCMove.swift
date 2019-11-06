/// A move of a player. Depending on the type of the move, it consists of a
/// start and destination coordinate or a piece and a destination coordinate.
struct SCMove {
    // MARK: - Properties

    /// The type of the move.
    let type: SCMoveType
    /// The start coordinate of a drag move.
    let start: SCCubeCoordinate?
    /// The destination coordinate of a drag or set move.
    let destination: SCCubeCoordinate?
    /// The piece used by a set move.
    let piece: SCPiece?
    /// The debug hints associated with the move.
    lazy var debugHints = [String]()

    // MARK: - Initializers

    /// Creates a new skip move.
    init() {
        self.type = .skipMove
        self.start = nil
        self.destination = nil
        self.piece = nil
    }

    /// Creates a new drag move from the given start coordinate to the given
    /// destination coordinate.
    ///
    /// - Parameters:
    ///   - start: The start coordinate of the drag move.
    ///   - destination: The destination coordinate of the drag move.
    init(start: SCCubeCoordinate, destination: SCCubeCoordinate) {
        self.type = .dragMove
        self.start = start
        self.destination = destination
        self.piece = nil
    }

    /// Creates a new set move with the given piece to the given destination
    /// coordinate.
    ///
    /// - Parameters:
    ///   - piece: The piece used by the set move.
    ///   - destination: The destination coordinate of the set move.
    init(piece: SCPiece, destination: SCCubeCoordinate) {
        self.type = .setMove
        self.start = nil
        self.destination = destination
        self.piece = piece
    }
}