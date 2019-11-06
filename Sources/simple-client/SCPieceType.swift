/// The type of a piece.
enum SCPieceType: String, CaseIterable, CustomStringConvertible {
    /// The piece representing an ant.
    case ant = "ANT"
    /// The piece representing a bee.
    case bee = "BEE"
    /// The piece representing a beetle.
    case beetle = "BEETLE"
    /// The piece representing a grasshopper.
    case grasshopper = "GRASSHOPPER"
    /// The piece representing a spider.
    case spider = "SPIDER"

    // MARK: - Initializers

    /// Creates a new piece type from the given short description.
    ///
    /// - Parameter shortDescription: The character that represents the piece
    ///   type.
    init?(shortDescription: Character) {
        switch shortDescription {
            case "A":
                self = .ant
            case "B":
                self = .beetle
            case "G":
                self = .grasshopper
            case "Q":
                self = .bee
            case "S":
                self = .spider
            default:
                return nil
        }
    }

    // MARK: - CustomStringConvertible

    var description: String {
        self.rawValue
    }
}