import Foundation

struct WebRouteResolver {
    private static let savedURLKey = "savedUrl"
    private static let probeUserAgent = "TestRequest/1.0 CFNetwork/1410.0.3 Darwin/22.4.0"

    let session: URLSession
    let defaults: UserDefaults

    init(session: URLSession = .shared, defaults: UserDefaults = .standard) {
        self.session = session
        self.defaults = defaults
    }

    func resolve(initialURL: String, attribution: AttributionData) async -> URL? {
        if let savedURL = defaults.string(forKey: Self.savedURLKey),
           let url = Self.webComponents(savedURL)?.url {
            return url
        }

        guard var components = Self.webComponents(initialURL) else { return nil }
        if let attributionQuery = AttributionData.encode(attribution.queryItems) {
            let existingQuery = components.percentEncodedQuery ?? ""
            components.percentEncodedQuery = existingQuery.isEmpty
                ? attributionQuery
                : existingQuery + "&" + attributionQuery
        }
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Self.probeUserAgent, forHTTPHeaderField: "User-Agent")

        do {
            let (_, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode), response.url != nil else { return nil }

            defaults.set(url.absoluteString, forKey: Self.savedURLKey)
            return url
        } catch {
            return nil
        }
    }

    private static func webComponents(_ string: String) -> URLComponents? {
        guard let components = URLComponents(string: string),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = components.host, !host.isEmpty else { return nil }
        return components
    }
}
