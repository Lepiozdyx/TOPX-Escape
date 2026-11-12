import SwiftUI

struct CollectionScreen: View {
    @ObservedObject var store: PlayerStore
    let feedback: FeedbackService
    @State private var kind: CosmeticKind = .field
    @State private var notice: String?
    private var items: [CosmeticItem] {kind == .field ? CosmeticCatalog.fields : CosmeticCatalog.balls}
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                HStack {SectionEyebrow(text:"Club collection");Spacer();WalletBadge(balance:store.save.coins)}
                Picker("Collection type",selection:$kind) {ForEach(CosmeticKind.allCases,id:\.self) {Text($0.rawValue).tag($0)}}.pickerStyle(.segmented)
                LazyVGrid(columns:[GridItem(.flexible(),spacing:12),GridItem(.flexible(),spacing:12)],spacing:14) {
                    ForEach(items) { item in
                        VStack(alignment:.leading,spacing:12) {
                            ZStack {
                                RoundedRectangle(cornerRadius:14).fill(PitchTheme.paper)
                                if item.kind == .field {
                                    PitchSurface(style:item.id).clipShape(RoundedRectangle(cornerRadius:10)).padding(9)
                                    FootballView(style:store.save.selectedBall).frame(width:28,height:28)
                                } else {FootballView(style:item.id).frame(width:78,height:78)}
                            }.frame(height:125)
                            Text(item.title).font(.system(size:17,weight:.semibold,design:.serif)).foregroundStyle(PitchTheme.ink).lineLimit(1).minimumScaleFactor(0.8)
                            Button {
                                let owned = store.owns(item)
                                if store.selectOrBuy(item) {notice = nil;feedback.play(owned ? .tap : .purchase)}
                                else {notice = "You need \(max(0,item.price-store.save.coins)) more coins. Earn new stars to unlock this item.";feedback.play(.tap)}
                            } label: {
                                HStack(spacing:5) {
                                    if store.isSelected(item) {SportIcon("check",size:13);Text("Equipped")}
                                    else if store.owns(item) {Text("Equip")}
                                    else {SportIcon("coin",size:14);Text("\(item.price)")}
                                }.font(.system(size:12,weight:.semibold)).frame(maxWidth:.infinity,minHeight:40)
                                    .foregroundStyle(store.isSelected(item) ? PitchTheme.red : Color.white)
                                    .background(store.isSelected(item) ? PitchTheme.red.opacity(0.08) : PitchTheme.red,in:RoundedRectangle(cornerRadius:10))
                            }.buttonStyle(.plain).disabled(store.isSelected(item))
                                .accessibilityLabel(store.isSelected(item) ? "\(item.title), equipped" : store.owns(item) ? "Equip \(item.title)" : "Buy \(item.title) for \(item.price) coins")
                        }.padding(12).background(.white,in:RoundedRectangle(cornerRadius:20))
                    }
                }
            }.padding(22)
        }.background(StadiumBackdrop()).navigationTitle("Collection").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge:.bottom) {
                if let notice {
                    HStack(alignment:.center,spacing:12) {
                        Text(notice).font(.system(size:12,weight:.medium)).foregroundStyle(PitchTheme.red)
                            .accessibilityAddTraits(.updatesFrequently)
                        Button {self.notice = nil} label: {SportIcon("close",size:16).frame(width:36,height:36)}
                            .buttonStyle(.plain).accessibilityLabel("Dismiss message")
                    }.padding(14).background(.white,in:RoundedRectangle(cornerRadius:16))
                        .overlay(RoundedRectangle(cornerRadius:16).strokeBorder(PitchTheme.line))
                        .padding(.horizontal,18).padding(.bottom,8)
                }
            }
            .onChange(of:kind) {_,_ in notice = nil}
    }
}
