/// The state of a field.
enum SCFieldState: String, CaseIterable, CustomStringConvertible {
    /// The field is owned by the red player.
    case red = "RED"
    /// The field is owned by the blue player.
    case blue = "BLUE"
    /// The field is blocked with a blackberry.
    case obstructed = "OBSTRUCTED"
    /// The field is empty.
    case empty = "EMPTY"

    // MARK: - CustomStringConvertible

    var description: String {
        self.rawValue
    }
}