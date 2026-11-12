import Foundation

// Frozen revision 2 content. Never derive archived attempts from current layouts.
enum StageArchive {
    static let chapters = [
        CampaignChapter(id: 1, title: "Read the pitch", subtitle: "Find the gaps. Close every exit.", number: "01"),
        CampaignChapter(id: 2, title: "Build your defense", subtitle: "Double walls. Smarter placement.", number: "02"),
        CampaignChapter(id: 3, title: "Control the pace", subtitle: "Anticipate the acceleration.", number: "03"),
        CampaignChapter(id: 4, title: "The final whistle", subtitle: "Adapt to a changing playing field.", number: "04")
    ]

    private static func stage(_ n: Int, _ title: String, _ briefing: String, _ par: Int, _ rows: [String]) -> StageLayout {
        StageLayout(id: "campaign-\(n)", number: n, chapter: (n - 1) / 4 + 1, title: title, briefing: briefing, map: rows, par: par,
                    supply: ToolSupply(barriers: nil, walls: n >= 2 ? 2 : 0, relocations: n >= 2 ? 2 : 0))
    }

    static let campaign: [StageLayout] = [
        stage(1, "The first barrier", "Tap to build. Watch the ball respond, then close its last escape route.", 2,
              [".......", ".......", ".##.##.", ".#...#.", ".#...#.", ".#.B.#.", ".#...#.", ".#...#.", ".##.##.", ".......", "......."]),
        StageLayout(id: "campaign-2", number: 2, chapter: 1, title: "A smarter defense",
                    briefing: "Close a wide gap with Double wall, then reuse your barrier with Relocate.",
                    map: [".......", ".......", ".#..##.", ".#...#.", ".#...#.", ".#.B.#.", ".#...#.", ".#...#.", ".##.##.", ".......", "......."],
                    par: 2, supply: ToolSupply(barriers: nil, walls: 1, relocations: 1),
                    initialBarriers: [PitchPosition(row: 7, column: 3)]),
        stage(3, "Split decision", "There are three gaps. Stay ahead of the ball and close every route.", 3,
              [".......", ".......", ".#..##.", ".#...#.", ".#...#.", ".#.B.#.", ".#...#.", ".#...#.", ".##.##.", ".......", "......."]),
        stage(4, "Wide open", "A narrow defensive line can close several routes at once. Plan before you place a barrier.", 4,
              [".......", "..#.#..", ".#...#.", ".#...#.", ".#.#.#.", ".#.B.#.", ".#...#.", ".#...#.", ".#..##.", ".......", "......."]),
        stage(5, "Stand together", "Double wall places two adjacent barriers in a single turn. You have two uses.", 2,
              [".......", ".......", ".#..##.", ".#...#.", ".#...#.", ".#.B.#.", ".#...#.", ".#...#.", ".##..#.", ".......", "......."]),
        stage(6, "Change the shape", "Relocate moves one of your barriers. Select its current tile, then a new empty tile.", 3,
              [".......", ".#..##.", ".#...#.", ".#.#.#.", ".#...#.", ".#.B.#.", ".#.#.#.", ".#...#.", ".#..##.", ".......", "......."]),
        stage(7, "The overlap", "Think in pairs. Each double wall should shut down more than one route.", 3,
              [".......", ".##..#.", ".#...#.", ".#.#.#.", ".....#.", ".#.B.#.", ".#...#.", ".#...#.", ".#..##.", ".......", "......."]),
        stage(8, "Hold the line", "Build a connected defense. Open flanks need attention before the ball gets close.", 4,
              [".......", ".#..##.", ".#...#.", ".#...#.", ".#.#...", ".#.B.#.", "...#.#.", ".#...#.", ".##..#.", ".......", "......."]),
        stage(9, "A burst of pace", "Striped tiles add one step in the direction of entry. Plan for the extra distance.", 2,
              [".......", ".......", ".##.##.", ".#...#.", ".#.>.#.", ".#.B.#.", ".#...#.", ".#...#.", ".##.##.", ".......", "......."]),
        stage(10, "Fast lanes", "Build ahead of the acceleration tiles. A barrier can stop the extra step.", 3,
              [".......", ".......", ".#..##.", ".#...#.", ".#>..#.", ".#.B.#.", ".#..>#.", ".#...#.", ".##..#.", ".......", "......."]),
        stage(11, "Break the rhythm", "The shortest route is counted in turns, including acceleration. Anticipate the next move.", 3,
              [".......", ".##..#.", ".#...#.", ".#.>.#.", ".#...#.", ".#.B.#.", "...#.#.", ".#>..#.", ".###.#.", ".......", "......."]),
        stage(12, "Counterpress", "Use the whole toolkit to contain a ball that can change direction quickly.", 4,
              [".......", ".#..##.", ".#...#.", ".#>..#.", "...#.#.", ".#.B.#.", ".#..>..", ".#...#.", ".##..#.", ".......", "......."]),
        stage(13, "Protected ground", "Hatched tiles cannot hold barriers. Close the routes before they reach that ground.", 2,
              [".......", ".......", ".##~##.", ".#...#.", ".#...#.", ".#.B.#.", ".#...#.", ".#...#.", ".##~##.", ".......", "......."]),
        stage(14, "Tight margins", "Protected gaps cannot be plugged directly. Build a line inside the pitch.", 3,
              [".......", ".##~.#.", ".#...#.", ".#...#.", ".#>..#.", ".#.B.#.", ".#..~#.", ".#...#.", ".#.~##.", ".......", "......."]),
        stage(15, "All angles", "Acceleration and protected ground combine. Every placement should have a purpose.", 4,
              [".......", ".#.~##.", ".#...#.", ".#>..#.", "..~#.#.", ".#.B.#.", ".#..>..", ".#...#.", ".##~.#.", ".......", "......."]),
        stage(16, "The final whistle", "One last defensive puzzle. Shut every route and complete your campaign.", 5,
              [".......", ".#.~.#.", ".#...#.", ".#>..#.", "..~#.#.", ".#.B.#.", ".#..>~.", ".#...#.", ".#.~.#.", ".......", "......."])
    ]

    static let challenges: [StageLayout] = {
        let source = [2, 3, 4, 6, 7, 9, 10, 11, 12, 13, 14, 15]
        let titles = ["Three clean touches", "Narrow victory", "Twin defense", "Protect the flank", "Under pressure", "Sprint finish", "Close quarters", "Full court press", "No easy gaps", "The inner line", "Last defender", "Championship point"]
        return source.enumerated().map { index, base in
            let original = campaign[base]
            let mirrored = original.map.enumerated().map { row, text -> String in
                let cells = Array(text)
                if row.isMultiple(of: 2) { return String(cells.reversed()) }
                // Fixed alternate layouts, authored from the campaign formations.
                return "." + String(cells.dropLast().reversed())
            }
            let target = original.par + (index >= 2 ? 1 : 0)
            return StageLayout(id: "challenge-\(index + 1)", number: index + 1, chapter: 0,
                               title: titles[index], briefing: "A fixed tactical setup. Close every exit before your turns or tools run out.",
                               map: mirrored, par: target, supply: ToolSupply(barriers: index < 3 ? 4 : 5, walls: index < 2 ? 0 : 1, relocations: index < 4 ? 0 : 1),
                               moveLimit: target + 3)
        }
    }()

    static func level(_ id: String, revision: Int? = 2) -> StageLayout? {
        guard let current = (campaign + challenges).first(where: { $0.id == id }) else { return nil }
        guard (revision ?? 1) < 2 else { return current }
        // Only the first two maps changed. Older attempts retain their map and par.
        guard id == "campaign-1" || id == "campaign-2" else { return current }
        let first = id == "campaign-1"
        return StageLayout(id: id, number: current.number, chapter: 1,
                           title: first ? "The first barrier" : "Two ways out", briefing: current.briefing,
                           map: [".......", ".......", first ? ".#####." : ".##.##.", ".#...#.", ".#...#.", ".#.B.#.", ".#...#.", ".#...#.", ".##.##.", ".......", "......."],
                           par: first ? 1 : 2, supply: ToolSupply(barriers: nil, walls: 0, relocations: 0), revision: 1)
    }
}
