import SwiftUI

struct FootballView: View {
    var style = 0
    var rotation: Double = 0
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width
            ZStack {
                Circle().fill(Color(hex: 0xF2EADF))
                Canvas { context, bounds in
                    let width = bounds.width
                    let center = CGPoint(x: width * 0.5, y: width * 0.46)
                    let radius = width * 0.205
                    let color = CosmeticCatalog.ball(style).color
                    var pentagon = Path()
                    var vertices: [CGPoint] = []
                    for i in 0..<5 {
                        let a = Double(i) * 2 * .pi / 5 - .pi / 2
                        vertices.append(CGPoint(x:center.x+cos(a)*radius,y:center.y+sin(a)*radius))
                    }
                    pentagon.addLines(vertices); pentagon.closeSubpath()
                    context.fill(pentagon, with:.color(color))
                    var seams = Path()
                    for vertex in vertices {
                        let edge = CGPoint(x:center.x+(vertex.x-center.x)*2.85,y:center.y+(vertex.y-center.y)*2.85)
                        seams.move(to:vertex); seams.addLine(to:edge)
                        var panel = Path()
                        panel.move(to:edge)
                        panel.addLine(to:CGPoint(x:edge.x-width*0.12,y:edge.y+width*0.12))
                        panel.addLine(to:CGPoint(x:edge.x+width*0.12,y:edge.y+width*0.12))
                        panel.closeSubpath(); context.fill(panel,with:.color(color))
                    }
                    context.stroke(seams,with:.color(Color.black.opacity(0.22)),style:StrokeStyle(lineWidth:width*0.012,lineCap:.round))
                }
                Circle().fill(RadialGradient(colors:[.white.opacity(0.6),.clear,.black.opacity(0.35)],center:.init(x:0.3,y:0.25),startRadius:0,endRadius:size*0.85))
                Circle().strokeBorder(.white.opacity(0.3),lineWidth:1)
            }.clipShape(Circle()).rotationEffect(.degrees(rotation)).shadow(color:.black.opacity(0.35),radius:size*0.12,x:0,y:size*0.08)
        }.aspectRatio(1,contentMode:.fit).accessibilityHidden(true)
    }
}
