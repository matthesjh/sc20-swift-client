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

    /// Returns the cube coordinate on the game board in the given direction
    /// with the given distance from this cube coordinate.
    ///
    /// - Parameters:
    ///   - direction: The direction on the game board.
    ///   - distance: The number of steps to be taken.
    ///
    /// - Returns: The cube coordinate on the game board in the given direction
    ///   with the given distance from this cube coordinate.
    func coordinate(inDirection direction: SCDirection, withDistance distance: Int = 1) -> SCCubeCoordinate {
        switch direction {
            case .upRight:
                return SCCubeCoordinate(x: self.x + distance, y: self.y - distance)
            case .right:
                return SCCubeCoordinate(x: self.x + distance, z: self.z - distance)
            case .downRight:
                return SCCubeCoordinate(y: self.y + distance, z: self.z - distance)
            case .downLeft:
                return SCCubeCoordinate(x: self.x - distance, y: self.y + distance)
            case .left:
                return SCCubeCoordinate(x: self.x - distance, z: self.z + distance)
            case .upLeft:
                return SCCubeCoordinate(y: self.y - distance, z: self.z + distance)
        }
    }

    /// Returns the distance to the given cube coordinate.
    ///
    /// - Parameter coordinate: The cube coordinate to which the distance should
    ///   be calculated.
    ///
    /// - Returns: The distance to the given cube coordinate.
    func distance(toCoordinate coordinate: SCCubeCoordinate) -> Int {
        max(abs(self.x - coordinate.x), abs(self.y - coordinate.y), abs(self.z - coordinate.z))
    }
}