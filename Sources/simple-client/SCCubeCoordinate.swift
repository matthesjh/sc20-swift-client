/// A cube coordinate consists of an x-, y- and z-coordinate and points to a
/// field on the game board.
struct SCCubeCoordinate {
    // MARK: - Properties

    /// The x-coordinate of the field.
    let x: Int
    /// The y-coordinate of the field.
    let y: Int
    /// The z-coordinate of the field.
    let z: Int

    // MARK: - Initializers

    /// Creates a new cube coordinate with the given x- and y-coordinate.
    ///
    /// The z-coordinate is computed by means of the x- and y-coordinate so that
    /// the following property holds.
    ///
    /// *z = -x - y*
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
        self.z = -x - y
    }

    /// Creates a new cube coordinate with the given x- and z-coordinate.
    ///
    /// The y-coordinate is computed by means of the x- and z-coordinate so that
    /// the following property holds.
    ///
    /// *y = -x - z*
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - z: The z-coordinate of the field.
    init(x: Int, z: Int) {
        self.x = x
        self.y = -x - z
        self.z = z
    }

    /// Creates a new cube coordinate with the given y- and z-coordinate.
    ///
    /// The x-coordinate is computed by means of the y- and z-coordinate so that
    /// the following property holds.
    ///
    /// *x = -y - z*
    ///
    /// - Parameters:
    ///   - y: The y-coordinate of the field.
    ///   - z: The z-coordinate of the field.
    init(y: Int, z: Int) {
        self.x = -y - z
        self.y = y
        self.z = z
    }

    // MARK: - Methods

    /// Returns the distance to the given cube coordinate.
    ///
    /// - Parameter coord: The cube coordinate to which the distance should be
    ///   calculated.
    ///
    /// - Returns: The distance to the given cube coordinate.
    func distance(toCoordinate coord: SCCubeCoordinate) -> Int {
        return (abs(self.x - coord.x) + abs(self.y - coord.y) + abs(self.z - coord.z)) / 2
    }
}