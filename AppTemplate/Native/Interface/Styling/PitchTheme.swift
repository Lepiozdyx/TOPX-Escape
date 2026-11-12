import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}

enum PitchTheme {
    static let red = Color(hex: 0xDF1929)
    static let paper = Color.white
    static let ink = Color(hex: 0x16171B)
    static let muted = Color(hex: 0x565860)
    static let line = Color(hex: 0xDADCE0)
    static let gold = Color(hex: 0xB58C4D)
    static let matchPanel = Color(hex: 0x183A2E)
    static let matchMuted = Color.white.opacity(0.78)
}

struct StadiumBackdrop: View {
    var body: some View { PitchTheme.paper.ignoresSafeArea() }
}

struct SectionEyebrow: View {
    let text: String
    var color = PitchTheme.red
    var body: some View {
        Text(text.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2.5).foregroundStyle(color)
    }
}

struct SportButtonStyle: ButtonStyle {
    var prominent = true
    var light = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(prominent || light ? .white : PitchTheme.ink)
            .background(prominent ? PitchTheme.red : light ? Color.white.opacity(0.1) : Color.white, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(prominent ? .clear : light ? .white.opacity(0.18) : PitchTheme.line))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct WalletBadge: View {
    let balance: Int
    var light = false
    var body: some View {
        HStack(spacing: 7) {
            SportIcon("coin", size: 18).foregroundStyle(light ? Color.white : PitchTheme.red)
            Text(balance.formatted()).font(.system(size: 14, weight: .semibold, design: .rounded)).monospacedDigit()
        }
        .padding(.horizontal, 13).padding(.vertical, 10)
        .foregroundStyle(light ? .white : PitchTheme.ink)
        .background(light ? Color.white.opacity(0.12) : Color.white, in: Capsule())
        .accessibilityElement(children: .ignore).accessibilityLabel("\(balance) coins")
    }
}

struct IconButton: View {
    let icon: String
    let label: String
    var light = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            SportIcon(icon, size: 19).frame(width: 44, height: 44)
                .foregroundStyle(light ? .white : PitchTheme.ink)
                .background(light ? Color.white.opacity(0.10) : Color.white, in: Circle())
        }.buttonStyle(.plain).accessibilityLabel(label)
    }
}

struct StarRating: View {
    let value: Int
    var size: CGFloat = 14
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in SportIcon("star", size: size).foregroundStyle(index < value ? PitchTheme.gold : PitchTheme.line) }
        }.accessibilityElement(children: .ignore).accessibilityLabel("\(value) of 3 stars")
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { content.padding(20).background(.white, in: RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(PitchTheme.line.opacity(0.6))) }
}

struct ScreenHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionEyebrow(text: eyebrow)
            Text(title).font(.system(size: 34, weight: .semibold, design: .serif)).foregroundStyle(PitchTheme.ink)
            Text(subtitle).font(.system(size: 14)).foregroundStyle(PitchTheme.muted).lineSpacing(4)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
