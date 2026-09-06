import Foundation

/// Mirrors the structure of `cube_data.json`, generated from the SERI
/// Q-methodology report's full 38-statement x 4-perspective score table.
/// See the project brief, section 3, for how each face's content was chosen.
struct CubeData: Codable {
    let source: String
    let participantCount: Int
    let consensusStatementIds: [String]
    let faces: [FaceData]
}

struct FaceData: Codable {
    let perspectiveId: String   // "P1"..."P4"
    let name: String            // e.g. "Skeptical Realism"
    let subtitle: String        // e.g. "Proceed Only with Full Accountability"
    let definingParticipants: Int
    let centerCubie: CubieData
    let cubies: [CubieData]      // 8 secondary statements
}

struct CubieData: Codable {
    let statementId: String
    let text: String
    let score: Double
    let polarity: String?       // "affirm" or "reject" — nil for the center cubie
    let isConsensus: Bool?      // nil for the center cubie
    let allScores: [String: Double]?  // nil for the center cubie

    var isConsensusStatement: Bool { isConsensus ?? false }
}

enum CubeDataLoader {
    /// Loads `cube_data.json` from the app bundle. This file must be added
    /// to the target's "Copy Bundle Resources" build phase — see
    /// SETUP.md.
    static func load() -> CubeData {
        guard let url = Bundle.main.url(forResource: "cube_data", withExtension: "json") else {
            fatalError("cube_data.json not found in the app bundle — add Resources/cube_data.json to the target's Copy Bundle Resources build phase.")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(CubeData.self, from: data)
        } catch {
            fatalError("Failed to decode cube_data.json: \(error)")
        }
    }
}
