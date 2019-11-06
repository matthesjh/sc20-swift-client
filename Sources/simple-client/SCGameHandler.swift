import Foundation

#if os(Linux)
import FoundationXML
#endif

/// The game handler is responsible for the communication with the game server
/// and the selection of the game logic.
class SCGameHandler: NSObject, XMLParserDelegate {
    // MARK: - Properties

    /// The TCP socket used for the communication with the game server.
    private let socket: SCSocket
    /// The reservation code to join a prepared game.
    private let reservation: String
    /// The strategy selected by the user.
    private let strategy: String

    /// The room id associated with the joined game.
    private var roomId: String!
    /// The player color of the delegate (game logic).
    private var playerColor: SCPlayerColor!
    /// The current state of the game.
    private var gameState: SCGameState!
    /// Indicates whether the game state has been initially created.
    private var gameStateCreated = false
    /// Indicates whether the game loop should be left.
    private var leaveGame = false

    /// The current player score which is parsed.
    private var score: SCScore!
    /// The scores of the players.
    private var scores = [SCScore]()
    /// The winner of the game.
    private var winner: SCWinner?
    /// Indicates whether the game result has been received.
    private var gameResultReceived = false

    /// The field that is currently processed.
    private var field: SCField!

    /// The type of the last move.
    private var lastMoveType: SCMoveType!
    /// The piece used by the last move.
    private var lastMovePiece: SCPiece!
    /// The coordinates of the last move.
    private var lastMoveCoords = [SCCubeCoordinate]()

    /// The characters found by the parser.
    private var foundChars = ""

    /// The delegate (game logic) which handles the requests of the game server.
    var delegate: SCGameHandlerDelegate?

    // MARK: - Initializers

    /// Creates a new game handler with the given TCP socket, the given
    /// reservation code and the given strategy.
    ///
    /// The TCP socket must already be connected before using this initializer.
    ///
    /// - Parameters:
    ///   - socket: The socket used for the communication with the game server.
    ///   - reservation: The reservation code to join a prepared game.
    ///   - strategy: The selected strategy.
    init(socket: SCSocket, reservation: String, strategy: String) {
        self.socket = socket
        self.reservation = reservation
        self.strategy = strategy
    }

    // MARK: - Methods

    /// Handles the game.
    func handleGame() {
        if self.reservation.isEmpty {
            // Join a game.
            self.socket.send(message: #"<protocol><join gameType="\#(SCConstants.gameIdentifier)" />"#)
        } else {
            // Join a prepared game.
            self.socket.send(message: #"<protocol><joinPrepared reservationCode="\#(self.reservation)" />"#)
        }

        // The root element for the received XML document. A temporary fix for
        // the XMLParser.
        guard let rootElem = "<root>".data(using: .utf8) else {
            return
        }

        // Loop until the game is over.
        while !self.leaveGame {
            // Receive the message from the game server.
            var data = Data()
            self.socket.receive(into: &data)

            // Parse the received XML document.
            let parser = XMLParser(data: rootElem + data)
            parser.delegate = self
            _ = parser.parse()
        }
    }

    /// Exits the game with the given error message.
    ///
    /// - Parameter error: The error message to print into the standard output.
    private func exitGame(withError error: String = "") {
        if !error.isEmpty {
            print("ERROR: \(error)")
        }

        self.leaveGame = true
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        // Reset the found characters.
        self.foundChars = ""

        switch elementName {
            case "data":
                // Check whether a class attribute exists.
                guard let classAttr = attributeDict["class"] else {
                    parser.abortParsing()
                    self.exitGame(withError: "The class attribute of the data element is missing!")
                    break
                }

                switch classAttr {
                    case "result":
                        self.gameResultReceived = true
                    case "sc.framework.plugins.protocol.MoveRequest":
                        guard var move = self.delegate?.onMoveRequested() else {
                            parser.abortParsing()
                            self.exitGame(withError: "No move has been sent!")
                            break
                        }

                        // Send the move returned by the game logic to the game
                        // server.
                        var mv = ""
                        switch move.type {
                            case .dragMove:
                                let start = move.start!
                                let dest = move.destination!
                                mv += #"<start x="\#(start.x)" y="\#(start.y)" z="\#(start.z)" /><destination x="\#(dest.x)" y="\#(dest.y)" z="\#(dest.z)" />"#
                            case .setMove:
                                let piece = move.piece!
                                let dest = move.destination!
                                mv += #"<piece owner="\#(piece.owner)" type="\#(piece.type)" /><destination x="\#(dest.x)" y="\#(dest.y)" z="\#(dest.z)" />"#
                            default:
                                break
                        }
                        mv += move.debugHints.reduce(into: "") { $0 += #"<hint content="\#($1)" />"# }
                        let moveType = "\(move.type)".lowercased()
                        self.socket.send(message: #"<room roomId="\#(self.roomId!)"><data class="\#(moveType)">\#(mv)</data></room>"#)
                    case "welcomeMessage":
                        guard let colorAttr = attributeDict["color"],
                              let color = SCPlayerColor(rawValue: colorAttr.uppercased()) else {
                            parser.abortParsing()
                            self.exitGame(withError: "The player color of the welcome message is missing or could not be parsed!")
                            break
                        }

                        // Save the player color of this game client.
                        self.playerColor = color
                    default:
                        break
                }
            case "destination", "start":
                guard let xAttr = attributeDict["x"], let x = Int(xAttr),
                      let yAttr = attributeDict["y"], let y = Int(yAttr) else {
                    parser.abortParsing()
                    self.exitGame(withError: "The start or destination coordinate could not be parsed!")
                    break
                }

                // Save the start or destination coordinate of the last move.
                self.lastMoveCoords.append(SCCubeCoordinate(x: x, y: y))
            case "field":
                if !self.gameStateCreated {
                    guard let xAttr = attributeDict["x"], let x = Int(xAttr),
                          let yAttr = attributeDict["y"], let y = Int(yAttr),
                          let obstructedAttr = attributeDict["isObstructed"],
                          let obstructed = Bool(obstructedAttr) else {
                        parser.abortParsing()
                        self.exitGame(withError: "The field could not be parsed!")
                        break
                    }

                    // Save the field into a temporary variable.
                    self.field = SCField(coordinate: SCCubeCoordinate(x: x, y: y), obstructed: obstructed)
                }
            case "joined":
                guard let roomId = attributeDict["roomId"] else {
                    parser.abortParsing()
                    self.exitGame(withError: "The room ID is missing!")
                    break
                }

                // Save the room id of the game.
                self.roomId = roomId
            case "lastMove":
                guard let classAttr = attributeDict["class"],
                      let type = SCMoveType(rawValue: classAttr.uppercased()) else {
                    parser.abortParsing()
                    self.exitGame(withError: "The last move could not be parsed!")
                    break
                }

                // Save the type of the last move.
                self.lastMoveType = type
            case "left":
                // Leave the game.
                parser.abortParsing()
                self.delegate?.onGameEnded()
                self.exitGame()
            case "piece":
                if !self.gameStateCreated || self.lastMoveType != nil {
                    guard let ownerAttr = attributeDict["owner"],
                          let owner = SCPlayerColor(rawValue: ownerAttr),
                          let typeAttr = attributeDict["type"],
                          let type = SCPieceType(rawValue: typeAttr) else {
                        parser.abortParsing()
                        self.exitGame(withError: "The piece could not be parsed!")
                        break
                    }

                    // Create the piece.
                    let piece = SCPiece(owner: owner, type: type)

                    // Use the piece for a field or the last move.
                    if self.lastMoveType != nil {
                        self.lastMovePiece = piece
                    } else {
                        self.field.pieces.append(piece)
                    }
                }
            case "score":
                guard let causeAttr = attributeDict["cause"],
                      let cause = SCScoreCause(rawValue: causeAttr) else {
                    parser.abortParsing()
                    self.exitGame(withError: "The score could not be parsed!")
                    break
                }

                // Create the score object.
                self.score = SCScore(cause: cause, reason: attributeDict["reason"])
            case "state":
                if !self.gameStateCreated {
                    guard let startPlayerAttr = attributeDict["startPlayerColor"],
                          let startPlayer = SCPlayerColor(rawValue: startPlayerAttr) else {
                        parser.abortParsing()
                        self.exitGame(withError: "The initial game state could not be parsed!")
                        break
                    }

                    // Create the initial game state.
                    self.gameState = SCGameState(startPlayer: startPlayer)

                    // TODO: Select the game logic based on the strategy.

                    // Create the game logic.
                    self.delegate = SCGameLogic(player: self.playerColor)
                }
            case "winner":
                guard let displayName = attributeDict["displayName"],
                      let colorAttr = attributeDict["color"],
                      let color = SCPlayerColor(rawValue: colorAttr) else {
                    parser.abortParsing()
                    self.exitGame(withError: "The winner could not be parsed!")
                    break
                }

                // Save the winner of the game.
                self.winner = SCWinner(displayName: displayName, player: color)
            default:
                break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.foundChars += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
            case "data":
                if self.gameResultReceived {
                    // Notify the delegate that the game result has been
                    // received.
                    self.delegate?.onGameResultReceived(SCGameResult(scores: self.scores, winner: self.winner))
                }
            case "field":
                if !self.gameStateCreated {
                    // Update the field on the board.
                    self.gameState.setField(field: self.field)
                }
            case "lastMove":
                // Create the last move.
                var lastMove = SCMove()
                switch self.lastMoveType {
                    case .dragMove:
                        lastMove = SCMove(start: self.lastMoveCoords.first!, destination: self.lastMoveCoords.last!)
                    case .setMove:
                        lastMove = SCMove(piece: self.lastMovePiece, destination: self.lastMoveCoords.last!)
                    default:
                        break
                }

                // Perform the last move on the game state.
                if !self.gameState.performMove(move: lastMove) {
                    parser.abortParsing()
                    self.exitGame(withError: "The last move could not be performed on the game state!")
                }

                // Destroy the last move.
                self.lastMoveType = nil
                self.lastMoveCoords.removeAll()
            case "part":
                // Add the found value to the current score object.
                self.score.values.append(self.foundChars)
            case "score":
                // Append the current score object to the array of scores.
                self.scores.append(self.score)
            case "state":
                self.gameStateCreated = true

                // Notify the delegate that the game state has been updated.
                self.delegate?.onGameStateUpdated(SCGameState(withGameState: self.gameState))
            default:
                break
        }
    }
}