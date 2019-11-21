/// A field on the game board. It consists of a cube coordinate, a stack of
/// pieces and a Boolean value indicating whether the field is blocked with a
/// blackberry.
struct SCField {
    // MARK: - Properties

    /// The cube coordinate of the field.
    let coordinate: SCCubeCoordinate
    /// Indicates whether the field is blocked with a blackberry.
    let obstructed: Bool
    /// The pieces on the field.
    var pieces = [SCPiece]()

    /// The state of the field.
    var state: SCFieldState {
        if self.obstructed {
            return .obstructed
        } else if let piece = self.pieces.last {
            return piece.owner.fieldState
        }

        return .empty
    }

    /// The owner of the field.
    var owner: SCPlayerColor? {
        self.obstructed ? nil : self.pieces.last?.owner
    }

    // MARK: - Initializers

    /// Creates a new field with the given x- and y-coordinate and an empty
    /// stack of pieces.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    ///   - obstructed: Indicates whether the field is blocked with a
    ///     blackberry.
    init(x: Int, y: Int, obstructed: Bool = false) {
        self.init(coordinate: SCCubeCoordinate(x: x, y: y), obstructed: obstructed)
    }

    /// Creates a new field with the given cube coordinate and an empty stack of
    /// pieces.
    ///
    /// - Parameters:
    ///   - coordinate: The cube coordinate of the field.
    ///   - obstructed: Indicates whether the field is blocked with a
    ///     blackberry.
    init(coordinate: SCCubeCoordinate, obstructed: Bool = false) {
        self.coordinate = coordinate
        self.obstructed = obstructed
    }

    // MARK: - Methods

    /// Returns a Boolean value indicating whether the field is covered with at
    /// least one piece.
    ///
    /// - Returns: `true` if the field is covered with at least one piece;
    ///   otherwise, `false`.
    func hasOwner() -> Bool {
        !self.pieces.isEmpty && !self.obstructed
    }

    /// Returns a Boolean value indicating whether the field is empty.
    ///
    /// - Returns: `true` if the field is empty; otherwise, `false`.
    func isEmpty() -> Bool {
        self.state == .empty
    }

    /// Returns a Boolean value indicating whether the field is owned by the
    /// given player.
    ///
    /// - Parameter player: The color of the player.
    ///
    /// - Returns: `true` if the field is owned by the given player; otherwise,
    ///   `false`.
    func isOwned(byPlayer player: SCPlayerColor) -> Bool {
        self.state == player.fieldState
    }

    /// Returns the distance to the given cube coordinate.
    ///
    /// - Parameter coordinate: The cube coordinate to which the distance should
    ///   be calculated.
    ///
    /// - Returns: The distance to the given cube coordinate.
    func distance(toCoordinate coordinate: SCCubeCoordinate) -> Int {
        self.coordinate.distance(toCoordinate: coordinate)
    }

    /// Returns the distance to the given field.
    ///
    /// - Parameter field: The field to which the distance should be calculated.
    ///
    /// - Returns: The distance to the given field.
    func distance(toField field: SCField) -> Int {
        self.coordinate.distance(toCoordinate: field.coordinate)
    }

    /// Returns a Boolean value indicating whether the given cube coordinate and
    /// the cube coordinate of this field can be connected with a straight line
    /// via one of the possible directions.
    ///
    /// - Parameter coordinate: The cube coordinate to check.
    ///
    /// - Returns: `true` if the cube coordinates can be connected with a
    ///   straight line via one of the possible directions; otherwise, `false`.
    func isOnLine(withCoordinate coordinate: SCCubeCoordinate) -> Bool {
        self.coordinate.isOnLine(withCoordinate: coordinate)
    }

    /// Returns a Boolean value indicating whether the given field and this
    /// field can be connected with a straight line via one of the possible
    /// directions.
    ///
    /// - Parameter field: The field to check.
    ///
    /// - Returns: `true` if the fields can be connected with a straight line
    ///   via one of the possible directions; otherwise, `false`.
    func isOnLine(withField field: SCField) -> Bool {
        self.coordinate.isOnLine(withCoordinate: field.coordinate)
    }

    /// Returns a Boolean value indicating whether this field is a neighbour of
    /// the given cube coordinate.
    ///
    /// - Parameter coordinate: The cube coordinate to check.
    ///
    /// - Returns: `true` if this field is a neighbour of the given cube
    ///   coordinate; otherwise, `false`.
    func isNeighbour(ofCoordinate coordinate: SCCubeCoordinate) -> Bool {
        self.coordinate.isNeighbour(ofCoordinate: coordinate)
    }

    /// Returns a Boolean value indicating whether this field is a neighbour of
    /// the given field.
    ///
    /// - Parameter field: The field to check.
    ///
    /// - Returns: `true` if this field is a neighbour of the given field;
    ///   otherwise, `false`.
    func isNeighbour(ofField field: SCField) -> Bool {
        self.coordinate.isNeighbour(ofCoordinate: field.coordinate)
    }
}