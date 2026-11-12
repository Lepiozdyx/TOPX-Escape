import SwiftUI

enum CosmeticKind: String, CaseIterable { case field = "Pitches", ball = "Footballs" }

struct CosmeticItem: Identifiable {
    let id: Int
    let kind: CosmeticKind
    let title: String
    let subtitle: String
    let price: Int
    let color: Color
}

enum CosmeticCatalog {
    static let fields = [
        CosmeticItem(id: 0, kind: .field, title: "Home ground", subtitle: "The timeless green", price: 0, color: Color(hex: 0x345A49)),
        CosmeticItem(id: 1, kind: .field, title: "Evening club", subtitle: "Under the floodlights", price: 50, color: Color(hex: 0x243D39)),
        CosmeticItem(id: 2, kind: .field, title: "Silver mist", subtitle: "A cool morning kickoff", price: 100, color: Color(hex: 0x4A625D)),
        CosmeticItem(id: 3, kind: .field, title: "Old stadium", subtitle: "Warm heritage grass", price: 150, color: Color(hex: 0x586147)),
        CosmeticItem(id: 4, kind: .field, title: "Midnight XI", subtitle: "The late-night fixture", price: 200, color: Color(hex: 0x263D48)),
        CosmeticItem(id: 5, kind: .field, title: "Grand final", subtitle: "The championship pitch", price: 250, color: Color(hex: 0x37574B))
    ]
    static let balls = [
        CosmeticItem(id: 0, kind: .ball, title: "Club original", subtitle: "Ivory & oxblood", price: 0, color: Color(hex: 0x8E263A)),
        CosmeticItem(id: 1, kind: .ball, title: "Heritage", subtitle: "A classic leather finish", price: 40, color: Color(hex: 0x895C42)),
        CosmeticItem(id: 2, kind: .ball, title: "Carbon", subtitle: "Clean graphite panels", price: 60, color: Color(hex: 0x30343B)),
        CosmeticItem(id: 3, kind: .ball, title: "Away kit", subtitle: "Deep midnight blue", price: 80, color: Color(hex: 0x344D72)),
        CosmeticItem(id: 4, kind: .ball, title: "Copper cup", subtitle: "Warm metallic accents", price: 100, color: Color(hex: 0xAF7843)),
        CosmeticItem(id: 5, kind: .ball, title: "Captain", subtitle: "A signature crimson", price: 120, color: Color(hex: 0xB41E3D))
    ]
    static func field(_ id: Int) -> CosmeticItem { fields.first { $0.id == id } ?? fields[0] }
    static func ball(_ id: Int) -> CosmeticItem { balls.first { $0.id == id } ?? balls[0] }
}
