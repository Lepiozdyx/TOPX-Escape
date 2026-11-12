import SwiftUI
import UIKit

struct ArcadePoster: View {
    let openSettings: () -> Void

    private let stripeRed = Color(hex: 0xBA1021)

    var body: some View {
        Canvas { context, size in
            let horizontalScale = size.width / 390
            let verticalScale = size.height / 402
            context.scaleBy(x: horizontalScale, y: verticalScale)
            context.translateBy(x: 0, y: -52)
            context.fill(Path(CGRect(x: 0, y: 52, width: 390, height: 402)), with: .color(PitchTheme.red))

            for index in 0..<6 {
                let offset = CGFloat(index) * 19
                context.fill(
                    polygon([(-25, 370 + offset), (395, 203 + offset),
                             (395, 207 + offset), (-25, 382 + offset)]),
                    with: .color(stripeRed)
                )
            }
            context.fill(polygon([(0, 401), (390, 275), (390, 422), (0, 463)]), with: .color(PitchTheme.ink))

            var printDots = Path()
            for row in 0..<16 {
                for column in 0..<76 {
                    let radius = 0.32 + CGFloat((row * 7 + column * 11) % 5) * 0.1
                    let x = 9 + CGFloat(column) * 5
                    let y = 360 + CGFloat(row) * 5
                    printDots.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: 2 * radius, height: 2 * radius))
                }
            }
            context.fill(printDots, with: .color(.white.opacity(0.22)))

            drawWord("TOPX", at: CGPoint(x: 20, y: 183), size: 104, in: context)
            drawWord("ESCAPE", at: CGPoint(x: 18, y: 245), size: 84, in: context)
            drawBall(in: context, aspect: verticalScale / horizontalScale)

            let streaks: [(CGPoint, CGPoint, CGFloat)] = [
                (CGPoint(x: 39, y: 348), CGPoint(x: 139, y: 315), 2.5),
                (CGPoint(x: 75, y: 355), CGPoint(x: 133, y: 337), 1.6),
                (CGPoint(x: 324, y: 253), CGPoint(x: 376, y: 236), 2),
                (CGPoint(x: 335, y: 262), CGPoint(x: 369, y: 251), 1.4)
            ]
            for (start, end, width) in streaks {
                let streak = Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                context.stroke(streak, with: .color(.white), style: StrokeStyle(lineWidth: width, lineCap: .round))
            }

            context.fill(polygon([(0, 454), (390, 425), (390, 456), (0, 456)]), with: .color(PitchTheme.paper))
        }
        .accessibilityHidden(true)
        .overlay(alignment: .topTrailing) {
            Button(action: openSettings) {
                SportIcon("settings", size: 23)
                    .foregroundStyle(PitchTheme.ink)
                    .frame(width: 44, height: 44)
                    .background(PitchTheme.paper, in: RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .padding(.trailing, 24)
            .padding(.top, 3)
        }
    }

    private func drawWord(_ word: String, at baseline: CGPoint, size: CGFloat, in context: GraphicsContext) {
        let face = "AvenirNextCondensed-HeavyItalic"
        let ascender = UIFont(name: face, size: size)?.ascender ?? size
        let text = Text(word).font(.custom(face, fixedSize: size)).tracking(-1.6).foregroundStyle(.white)
        context.draw(text, at: CGPoint(x: baseline.x, y: baseline.y - ascender), anchor: .topLeading)
    }

    private func drawBall(in context: GraphicsContext, aspect: CGFloat) {
        var ball = context
        ball.translateBy(x: 246, y: 356)
        // Counter the poster's compact-height scaling so the ball stays round.
        ball.scaleBy(x: 0.98 * min(1, aspect), y: 0.98 / max(1, aspect))
        let outline = Path(ellipseIn: CGRect(x: -100, y: -100, width: 200, height: 200))
        ball.fill(outline, with: .color(.white))

        var panels = ball
        panels.clip(to: outline)
        let angles = (0..<5).map { -2.0 + Double($0) * 2 * .pi / 5 }
        let inner = angles.map { CGPoint(x: -9 + cos($0) * 37, y: -12 + sin($0) * 37) }
        let outer = angles.map { CGPoint(x: -9 + cos($0) * 83, y: -12 + sin($0) * 83) }
        panels.fill(polygon(inner.map { ($0.x, $0.y) }), with: .color(PitchTheme.ink))

        for (inside, outside) in zip(inner, outer) {
            let seam = Path { path in
                path.move(to: inside)
                path.addLine(to: outside)
            }
            panels.stroke(seam, with: .color(PitchTheme.ink), lineWidth: 2.4)
            let angle = atan2(outside.y, outside.x)
            let dx = cos(angle)
            let dy = sin(angle)
            let patch = polygon([
                (outside.x, outside.y),
                (outside.x - 26 * dy + 9 * dx, outside.y + 26 * dx + 9 * dy),
                (outside.x - 24 * dy + 49 * dx, outside.y + 24 * dx + 49 * dy),
                (outside.x + 22 * dy + 49 * dx, outside.y - 22 * dx + 49 * dy),
                (outside.x + 25 * dy + 10 * dx, outside.y - 25 * dx + 10 * dy)
            ])
            panels.fill(patch, with: .color(PitchTheme.ink))
        }

        var halftone = Path()
        for row in 0..<28 {
            for column in 0..<40 {
                let x = CGFloat(column) * 5 - 100
                let y = CGFloat(row) * 4 + 1
                guard (x + 35) * 0.37 + y > 45 else { continue }
                let radius = 0.5 + 0.82 * min(1, (y + x * 0.3) / 110)
                halftone.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: 2 * radius, height: 2 * radius))
            }
        }
        panels.fill(halftone, with: .color(PitchTheme.ink.opacity(0.4)))
        ball.stroke(outline, with: .color(PitchTheme.ink), lineWidth: 3.6)
    }

    private func polygon(_ points: [(CGFloat, CGFloat)]) -> Path {
        Path { path in
            path.addLines(points.map { CGPoint(x: $0.0, y: $0.1) })
            path.closeSubpath()
        }
    }
}
