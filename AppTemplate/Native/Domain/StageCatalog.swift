import Foundation

struct CampaignChapter: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let number: String
}

enum StageCatalog {
    static let chapters = StageArchive.chapters

    private static func stage(_ n: Int, _ title: String, _ briefing: String, _ par: Int, _ rows: [String]) -> StageLayout {
        StageLayout(id: "campaign-\(n)", number: n, chapter: (n - 1) / 4 + 1,
                    title: title, briefing: briefing, map: rows, par: par,
                    supply: ToolSupply(barriers: nil, walls: 2, relocations: 2), revision: 3)
    }

    // Lessons retain their original maps, supplies, instructions and revision.
    static let campaign: [StageLayout] = Array(StageArchive.campaign.prefix(2)) + [
        stage(3, "Split decision", "Several flanks are open. Build ahead of the ball instead of chasing its nearest exit.", 5,
              [".......", "..#.#..", ".#...#.", ".....#.", ".......", ".#.B...", ".....#.", ".#.....", ".#..##.", "..#....", "......."]),
        stage(4, "Wide open", "The center connects to both wings. Choose the side you can defend before committing.", 5,
              [".......", "...#...", ".#..#..", ".#.....", "....##.", "..#B...", ".....#.", ".#.....", "..#..#.", "....#..", "......."]),
        stage(5, "Stand together", "Use a double wall to shape the next route, not merely to block one tile.", 5,
              [".......", "..#....", "....##.", ".#.....", ".....#.", ".#.B...", "...#...", ".....#.", ".#..#..", "...#...", "......."]),
        stage(6, "Change the shape", "A barrier can buy time on one flank and then become part of another defensive line.", 6,
              [".......", "....#..", ".#.....", "...#.#.", ".......", "..#B.#.", ".#.....", "....#..", ".#.....", "..#.#..", "......."]),
        stage(7, "The overlap", "Several exits share approach tiles. Connect your walls before those routes split.", 6,
              [".......", "..#....", ".#...#.", ".......", "..#..#.", "...B...", ".#.#...", ".......", "..#..#.", "...#...", "......."]),
        stage(8, "Hold the line", "Leave room to redirect the ball. A wall placed too close can expose the opposite wing.", 6,
              [".......", "....#..", "..#....", ".#.....", "....#..", "...B.#.", "..#....", ".....#.", ".#.....", "...#...", "......."]),
        stage(9, "A burst of pace", "The fast route competes with several ordinary exits. Stop the burst before it reaches the flank.", 6,
              [".......", "...#...", ".#...#.", "..>....", ".....#.", ".#.B...", "....>..", "..#....", ".#...#.", "...#...", "......."]),
        stage(10, "Fast lanes", "Two acceleration lanes lead to different edges. Build where the lanes can still be redirected.", 6,
              [".......", "..#....", "....#..", ".#..>..", "...#...", "...B.#.", ".>.....", ".....#.", "..#....", "....#..", "......."]),
        stage(11, "Break the rhythm", "A longer-looking route can escape sooner. Use the anchors to control both tempos.", 7,
              [".......", "....#..", ".#.....", "...>...", "..#..#.", "...B...", ".#..>..", ".......", "..#..#.", "...#...", "......."]),
        stage(12, "Counterpress", "Closing one fast lane exposes another. Keep a wall in reserve for the final change of direction.", 7,
              [".......", "..#....", ".....#.", ".#..>..", ".......", "..#B...", "....>#.", ".>.....", "...#...", ".#...#.", "......."]),
        stage(13, "Protected ground", "Protected passages stay open. Build a wider defensive line before the ball enters them.", 6,
              [".......", "...#...", ".#..~#.", "..~....", ".....#.", ".#.B...", "....~..", "..#....", ".#.~.#.", "....#..", "......."]),
        stage(14, "Tight margins", "Protected ground breaks the obvious wall. Find a line that also contains the acceleration lane.", 7,
              [".......", "..#....", "....~#.", ".#..>..", "..~....", "...B.#.", ".>.....", "....~..", ".#..#..", "...#...", "......."]),
        stage(15, "All angles", "Every flank has a second route. Redirect early and keep your final closure buildable.", 7,
              [".......", "....#..", ".#.~...", "...>...", "..#..~.", "...B.#.", ".~..>..", "..#....", ".....#.", "...#...", "......."]),
        stage(16, "The final whistle", "Read the entire pitch. Fast lanes, protected approaches and open wings demand a connected defense.", 8,
              [".......", "..#....", "....~..", ".#..>..", "..~..#.", "...B...", ".>..~..", "..#....", "....>#.", ".#.~...", "......."])
    ]

    private static func challenge(_ n: Int, _ title: String, _ par: Int, _ limit: Int,
                                  _ barriers: Int, _ walls: Int, _ relocations: Int, _ rows: [String]) -> StageLayout {
        StageLayout(id: "challenge-\(n)", number: n, chapter: 0, title: title,
                    briefing: "A fixed tactical setup. Close every exit before your turns or tools run out.",
                    map: rows, par: par, supply: ToolSupply(barriers: barriers, walls: walls, relocations: relocations),
                    moveLimit: limit, revision: 3)
    }

    // Authored independently: campaign edits must not change challenge maps or limits.
    static let challenges: [StageLayout] = [
        challenge(1, "Three clean touches", 5, 7, 5, 2, 0,
                  [".......", "...#...", ".#.....", ".....#.", "..#....", "...B.#.", ".#.....", "...#...", ".....#.", "..#....", "......."]),
        challenge(2, "Narrow victory", 5, 7, 4, 2, 1,
                  [".......", "..#....", ".....#.", ".#.....", "....#..", "..#B...", ".....#.", ".#.....", "...#...", "....#..", "......."]),
        challenge(3, "Twin defense", 5, 6, 3, 2, 1,
                  [".......", "....#..", "..#....", ".#.....", ".....#.", "...B...", ".#.#...", ".....#.", "..#....", "...#...", "......."]),
        challenge(4, "Protect the flank", 6, 8, 5, 2, 1,
                  [".......", "..#....", "....#..", ".#.....", "...#...", "...B.#.", ".......", ".#...#.", "..#....", "....#..", "......."]),
        challenge(5, "Under pressure", 6, 7, 4, 2, 2,
                  [".......", "...#...", ".#.....", "....>#.", ".......", "..#B...", ".....#.", ".#.....", "...#...", "....#..", "......."]),
        challenge(6, "Sprint finish", 6, 8, 5, 2, 1,
                  [".......", "....#..", ".#.....", "..>....", ".....#.", "...B...", "..#..>.", ".#.....", "....#..", "...#...", "......."]),
        challenge(7, "Close quarters", 6, 7, 4, 2, 1,
                  [".......", "..#....", "....#..", ".#..>..", ".......", "...B.#.", ".~.....", "..#....", ".....#.", "...#...", "......."]),
        challenge(8, "Full court press", 7, 8, 5, 2, 1,
                  [".......", "...#...", ".#.....", "....>..", "..#....", "...B...", ".....#.", ".>.....", "...#...", "..#..#.", "......."]),
        challenge(9, "No easy gaps", 6, 7, 4, 2, 2,
                  [".......", "....#..", ".#..~..", "...#...", ".....#.", "...B...", ".#..~..", "..~....", "....#..", "..#....", "......."]),
        challenge(10, "The inner line", 7, 8, 5, 2, 1,
                  [".......", "..#....", ".....#.", ".~..>..", "..#....", "...B...", ".#..~..", ".......", "...#.#.", "....#..", "......."]),
        challenge(11, "Last defender", 7, 8, 4, 2, 2,
                  [".......", "...#...", ".#.~...", "....>..", ".......", "..#B.#.", "....~..", ".>.....", "...#...", ".....#.", "......."]),
        challenge(12, "Championship point", 8, 9, 5, 2, 2,
                  [".......", "....#..", "..~....", ".#..>..", ".....#.", "...B...", ".>..~..", "..#....", "....>..", ".#.~.#.", "......."])
    ]

    static func level(_ id: String, revision: Int? = 3) -> StageLayout? {
        if (revision ?? 1) < 3 { return StageArchive.level(id, revision: revision) }
        return (campaign + challenges).first { $0.id == id }
    }
}
