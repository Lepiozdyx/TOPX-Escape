import SwiftUI

struct SportIcon: View {
    let name: String
    let size: CGFloat
    init(_ name: String, size: CGFloat = 22) { self.name = name; self.size = size }
    var body: some View {
        Canvas { context, bounds in
            let scale = bounds.width / 24
            context.scaleBy(x: scale, y: scale)
            var path = Path()
            func line(_ points: [CGPoint]) {
                guard let first = points.first else { return }
                path.move(to: first); for point in points.dropFirst() { path.addLine(to: point) }
            }
            func pts(_ values: [(Double, Double)]) { line(values.map { CGPoint(x: $0.0, y: $0.1) }) }
            switch name {
            case "star":
                for index in 0..<10 {
                    let angle = Double(index) * .pi / 5 - .pi / 2
                    let radius: Double = index.isMultiple(of: 2) ? 10 : 4.7
                    let point = CGPoint(x: 12 + cos(angle) * radius, y: 12 + sin(angle) * radius)
                    if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                path.closeSubpath(); context.fill(path, with: .foreground); return
            case "back": pts([(15,5),(8,12),(15,19)])
            case "arrow": pts([(5,12),(19,12)]); pts([(13,6),(19,12),(13,18)])
            case "close": pts([(6,6),(18,18)]); pts([(18,6),(6,18)])
            case "pause": pts([(8,5),(8,19)]); pts([(16,5),(16,19)])
            case "play": pts([(8,4),(20,12),(8,20),(8,4)])
            case "check": pts([(4,12),(9,17),(20,6)])
            case "undo": pts([(8,4),(3,9),(8,14)]); pts([(3,9),(14,9)])
                path.addArc(center: CGPoint(x: 14,y:14), radius: 5, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
                pts([(14,19),(10,19)])
            case "barrier":
                path.addRoundedRect(in: CGRect(x: 4,y:7,width:16,height:10), cornerSize: CGSize(width:2,height:2))
                pts([(8,8),(5,13)]); pts([(14,8),(9,16)]); pts([(20,9),(15,16)])
            case "wall":
                path.addRoundedRect(in: CGRect(x:2,y:5,width:9,height:14), cornerSize: CGSize(width:2,height:2))
                path.addRoundedRect(in: CGRect(x:13,y:5,width:9,height:14), cornerSize: CGSize(width:2,height:2))
                pts([(8,7),(4,14)]); pts([(20,8),(15,16)])
            case "relocate": pts([(3,8),(19,8),(15,4)]); pts([(21,16),(5,16),(9,20)])
            case "lock":
                path.addRoundedRect(in: CGRect(x:5,y:10,width:14,height:11), cornerSize: CGSize(width:2,height:2))
                path.move(to: CGPoint(x:8,y:10)); path.addLine(to: CGPoint(x:8,y:7)); path.addArc(center: CGPoint(x:12,y:7), radius:4, startAngle:.degrees(180), endAngle:.degrees(0), clockwise:false); pts([(16,7),(16,10)]); pts([(12,14),(12,17)])
            case "coin":
                path.addEllipse(in: CGRect(x:2,y:2,width:20,height:20)); path.addEllipse(in:CGRect(x:6,y:6,width:12,height:12)); pts([(12,9),(12,15)])
            case "trophy":
                pts([(6,3),(18,3),(17,12),(12,16),(7,12),(6,3)]); pts([(12,16),(12,21)]); pts([(7,21),(17,21)]); pts([(6,6),(2,6),(3,12),(7,13)]); pts([(18,6),(22,6),(21,12),(17,13)])
            case "settings":
                path.addEllipse(in: CGRect(x:8,y:8,width:8,height:8)); path.addEllipse(in:CGRect(x:4,y:4,width:16,height:16))
                for index in 0..<8 { let a = Double(index) * .pi / 4; line([CGPoint(x:12+cos(a)*8,y:12+sin(a)*8),CGPoint(x:12+cos(a)*11,y:12+sin(a)*11)]) }
            case "shop":
                path.addRoundedRect(in: CGRect(x:4,y:7,width:16,height:14), cornerSize: CGSize(width:2,height:2)); path.move(to:CGPoint(x:8,y:9)); path.addLine(to:CGPoint(x:8,y:6)); path.addArc(center:CGPoint(x:12,y:6),radius:4,startAngle:.degrees(180),endAngle:.degrees(0),clockwise:false); pts([(16,6),(16,9)])
            case "collection":
                pts([(4,7),(12,2.5),(20,7),(20,16.5),(12,21),(4,16.5),(4,7)])
                pts([(4,7),(12,11.5),(20,7)]); pts([(12,11.5),(12,21)])
            case "rules":
                pts([(12,5),(3,3),(3,19),(12,21),(21,19),(21,3),(12,5),(12,21)]); pts([(6,8),(9,9)]); pts([(15,9),(18,8)]); pts([(6,12),(9,13)]); pts([(15,13),(18,12)])
            case "campaign":
                path.addRoundedRect(in:CGRect(x:3,y:2,width:18,height:20),cornerSize:CGSize(width:3,height:3)); pts([(3,12),(21,12)]); path.addEllipse(in:CGRect(x:8,y:8,width:8,height:8)); pts([(8,2),(8,5),(16,5),(16,2)]); pts([(8,22),(8,19),(16,19),(16,22)])
            case "boost": pts([(5,4),(13,12),(5,20)]); pts([(12,4),(20,12),(12,20)])
            case "shield": pts([(12,2),(21,6),(20,15),(12,22),(4,15),(3,6),(12,2)]); pts([(8,12),(11,15),(17,8)])
            case "music": pts([(8,17),(8,5),(20,2),(20,14)]); path.addEllipse(in:CGRect(x:2,y:15,width:6,height:6)); path.addEllipse(in:CGRect(x:14,y:12,width:6,height:6)); pts([(8,9),(20,6)])
            case "sound": pts([(3,9),(7,9),(12,4),(12,20),(7,15),(3,15),(3,9)]); path.addArc(center:CGPoint(x:12,y:12),radius:7,startAngle:.degrees(-50),endAngle:.degrees(50),clockwise:false); path.addArc(center:CGPoint(x:12,y:12),radius:11,startAngle:.degrees(-50),endAngle:.degrees(50),clockwise:false)
            case "haptic": path.addRoundedRect(in:CGRect(x:8,y:3,width:8,height:18),cornerSize:CGSize(width:2,height:2)); pts([(4,6),(2,9),(4,12),(2,15),(4,18)]); pts([(20,6),(22,9),(20,12),(22,15),(20,18)])
            default: path.addEllipse(in:CGRect(x:3,y:3,width:18,height:18)); pts([(12,7),(12,13)]); path.addEllipse(in:CGRect(x:11.3,y:16,width:1.4,height:1.4))
            }
            context.stroke(path, with: .foreground, style: StrokeStyle(lineWidth:1.65,lineCap:.round,lineJoin:.round))
        }.frame(width:size,height:size).accessibilityHidden(true)
    }
}
