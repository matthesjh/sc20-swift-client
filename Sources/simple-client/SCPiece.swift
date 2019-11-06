/// A piece represents an insect tile of a player.
struct SCPiece {
    // MARK: - Properties

    /// The owner of the piece.
    let owner: SCPlayerColor
    /// The type of the piece.
    let type: SCPieceType

    // MARK: - Initializers

    /// Creates a new piece with the given owner and type.
    ///
    /// - Parameters:
    ///   - owner: The owner of the piece.
    ///   - type: The type of the piece.
    init(owner: SCPlayerColor, type: SCPieceType) {
        self.owner = owner
        self.type = type
    }
}