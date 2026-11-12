import SwiftUI

struct HexTile: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points = [CGPoint(x:rect.midX,y:rect.minY),CGPoint(x:rect.maxX,y:rect.height*0.25),CGPoint(x:rect.maxX,y:rect.height*0.75),CGPoint(x:rect.midX,y:rect.maxY),CGPoint(x:rect.minX,y:rect.height*0.75),CGPoint(x:rect.minX,y:rect.height*0.25)]
        path.addLines(points); path.closeSubpath(); return path
    }
}

struct BoardGeometry {
    let size: CGSize
    var cell: CGFloat { min((size.width-22)/7.5,(size.height-24)/9.65) }
    func point(_ position: PitchPosition) -> CGPoint {
        CGPoint(x:(size.width-7.5*cell)/2+cell/2+CGFloat(position.column)*cell+(position.row.isMultiple(of:2) ? 0 : cell/2),
                y:(size.height-9.6*cell)/2+cell/2+CGFloat(position.row)*cell*0.86)
    }
}

struct PitchBoard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let level: StageLayout
    let snapshot: MatchSnapshot
    var selected: [PitchPosition] = []
    var highlighted: Set<PitchPosition> = []
    var tool: TacticalTool = .barrier
    var suggestedTool: TacticalTool?
    var visibleBall: PitchPosition
    var trail: [PitchPosition] = []
    var fieldStyle = 0
    var ballStyle = 0
    var rotation: Double = 0
    var interactive = true
    var onTap: (PitchPosition) -> Void = { _ in }

    var body: some View {
        GeometryReader { geometry in
            let board = BoardGeometry(size:geometry.size)
            ZStack {
                PitchSurface(style:fieldStyle)
                ForEach(PitchRules.positions) { position in
                    let blocked = level.blocked.contains(position)
                    let barrier = snapshot.barriers.contains(position)
                    let chosen = selected.contains(position)
                    let suggested = highlighted.contains(position)
                    Button { onTap(position) } label: {
                        ZStack {
                            HexTile().fill(tileColor(position, blocked:blocked, barrier:barrier, chosen:chosen))
                            HexTile().strokeBorderCompatible(chosen ? Color.white : Color.white.opacity(blocked ? 0.07 : 0.17), lineWidth:chosen ? 2 : 0.6)
                            if suggested {
                                HexTile().fill(.white.opacity(0.18))
                                HexTile().stroke(.white, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                            }
                            if blocked || barrier {
                                SportIcon("barrier",size:board.cell*0.48).foregroundStyle(barrier ? Color(hex:0xFFF1DD) : Color.white.opacity(0.32))
                            } else if chosen && !(tool == .relocate && selected.first == position) {
                                SportIcon("barrier",size:board.cell*0.45).foregroundStyle(.white)
                            } else if level.boosts.contains(position) {
                                SportIcon("boost",size:board.cell*0.4).foregroundStyle(Color(hex:0xE2C58D))
                            } else if level.noBuild.contains(position) {
                                Path { p in
                                    p.move(to:CGPoint(x:board.cell*0.2,y:board.cell*0.65)); p.addLine(to:CGPoint(x:board.cell*0.7,y:board.cell*0.2))
                                    p.move(to:CGPoint(x:board.cell*0.4,y:board.cell*0.75)); p.addLine(to:CGPoint(x:board.cell*0.8,y:board.cell*0.4))
                                }.stroke(.white.opacity(0.4),lineWidth:1.5)
                            } else if position.isBoundary {
                                Circle().fill(.white.opacity(0.3)).frame(width:3,height:3)
                            }
                        }.frame(width:board.cell-3,height:board.cell*0.95-2).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain).disabled(!interactive)
                    .animation(reduceMotion ? nil : .easeOut(duration:0.18), value: snapshot.barriers)
                    .position(board.point(position))
                    .accessibilityLabel(accessibilityLabel(position, blocked:blocked, barrier:barrier))
                    .accessibilityAddTraits(chosen ? .isSelected : [])
                    .accessibilityHint(chosen ? "Tap again to cancel this unfinished selection." : suggested ? "Highlighted training tile. Choose \((suggestedTool ?? tool).title). \((suggestedTool ?? tool).instructions)" : tool.instructions)
                    .accessibilitySortPriority(suggested ? 1 : 0)
                }
                if trail.count > 2 {
                    route(trail,board:board).stroke(.white.opacity(0.4),style:StrokeStyle(lineWidth:4,lineCap:.round)).blur(radius:2).allowsHitTesting(false)
                }
                FootballView(style:ballStyle,rotation:rotation)
                    .frame(width:board.cell*0.78,height:board.cell*0.78)
                    .position(board.point(visibleBall)).allowsHitTesting(false)
            }.clipShape(RoundedRectangle(cornerRadius:22))
                .overlay(RoundedRectangle(cornerRadius:22).strokeBorder(.white.opacity(0.12)))
        }
    }
    private func route(_ positions: [PitchPosition], board: BoardGeometry) -> Path {
        Path { path in path.addLines(positions.map { board.point($0) }) }
    }
    private func tileColor(_ position: PitchPosition, blocked: Bool, barrier: Bool, chosen: Bool) -> Color {
        if chosen { return PitchTheme.red.opacity(0.95) }
        if barrier { return PitchTheme.red.opacity(0.88) }
        if blocked { return Color.black.opacity(0.28) }
        if level.noBuild.contains(position) { return Color.white.opacity(0.035) }
        return Color.white.opacity(position.isBoundary ? 0.02 : 0.07)
    }
    private func accessibilityLabel(_ position: PitchPosition, blocked: Bool, barrier: Bool) -> String {
        let state = position == visibleBall ? "ball" : blocked ? "fixed barrier" : barrier ? "your barrier" : level.boosts.contains(position) ? "acceleration tile" : level.noBuild.contains(position) ? "protected ground" : position.isBoundary ? "exit tile" : "empty"
        return "Row \(position.row+1), column \(position.column+1), \(state)"
    }
}

extension Shape {
    func strokeBorderCompatible(_ color: Color, lineWidth: CGFloat) -> some View { stroke(color,lineWidth:lineWidth) }
}

struct PitchSurface: View {
    var style = 0
    var showsMarkings = true
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CosmeticCatalog.field(style).color
                HStack(spacing:0) {
                    ForEach(0..<7) { index in Rectangle().fill(index.isMultiple(of:2) ? Color.white.opacity(0.025) : Color.black.opacity(0.025)) }
                }
                Canvas { context,size in
                    if showsMarkings {
                        var lines = Path()
                        let rect = CGRect(x:12,y:12,width:size.width-24,height:size.height-24)
                        lines.addRoundedRect(in:rect,cornerSize:CGSize(width:3,height:3))
                        lines.move(to:CGPoint(x:12,y:size.height/2)); lines.addLine(to:CGPoint(x:size.width-12,y:size.height/2))
                        lines.addEllipse(in:CGRect(x:size.width/2-38,y:size.height/2-38,width:76,height:76))
                        lines.addRect(CGRect(x:size.width*0.27,y:12,width:size.width*0.46,height:size.height*0.12))
                        lines.addRect(CGRect(x:size.width*0.27,y:size.height-size.height*0.12-12,width:size.width*0.46,height:size.height*0.12))
                        context.stroke(lines,with:.color(.white.opacity(0.17)),lineWidth:1)
                    }
                    // Deterministic fine grass grain, with no external texture dependency.
                    for index in 0..<400 {
                        let x = CGFloat((index*73+19)%997)/997*size.width
                        let y = CGFloat((index*131+7)%991)/991*size.height
                        var blade = Path(); blade.move(to:CGPoint(x:x,y:y)); blade.addLine(to:CGPoint(x:x+0.7,y:y-2))
                        context.stroke(blade,with:.color(.white.opacity(0.035)),lineWidth:0.6)
                    }
                }
                LinearGradient(colors:[.black.opacity(0.16),.clear,.black.opacity(0.13)],startPoint:.topLeading,endPoint:.bottomTrailing)
            }.frame(width:geometry.size.width,height:geometry.size.height)
        }
    }
}
