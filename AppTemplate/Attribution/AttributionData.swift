import Foundation

struct AttributionData {
    let campaignParameters: [URLQueryItem]
    let appsFlyerID: String

    var queryItems: [URLQueryItem] {
        guard !appsFlyerID.isEmpty else { return campaignParameters }
        return campaignParameters + [URLQueryItem(name: "afid", value: appsFlyerID)]
    }

    static func encode(_ items: [URLQueryItem]) -> String? {
        guard !items.isEmpty else { return nil }
        var components = URLComponents()
        components.queryItems = items
        return components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
    }
}
