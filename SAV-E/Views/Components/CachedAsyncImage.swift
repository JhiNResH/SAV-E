import SwiftUI

/// Drop-in replacement for `AsyncImage` that keeps decoded images in an
/// in-memory `NSCache` and reuses `URLCache.shared` for disk persistence.
///
/// Once a photo has loaded for a URL it renders instantly on every subsequent
/// open, so place sheets never re-show a spinner for a photo they have shown
/// before. The `phase` content closure mirrors SwiftUI's `AsyncImage` so call
/// sites can swap with minimal change.
struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty

    init(
        url: URL?,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            .task(id: url) {
                await load()
            }
    }

    private func load() async {
        guard let url else {
            phase = .empty
            return
        }

        if let cached = CachedImageStore.shared.image(for: url) {
            phase = .success(Image(uiImage: cached))
            return
        }

        phase = .empty

        do {
            let image = try await CachedImageStore.shared.loadImage(for: url)
            guard !Task.isCancelled else { return }
            phase = .success(Image(uiImage: image))
        } catch {
            guard !Task.isCancelled else { return }
            phase = .failure(error)
        }
    }
}

/// Shared image cache backed by an in-memory `NSCache` (fast, evictable) with
/// disk caching delegated to `URLCache.shared` (configured in `SaveApp`).
final class CachedImageStore {
    static let shared = CachedImageStore()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    private init() {
        memoryCache.countLimit = 200
        // `URLCache.shared` is configured at app launch and handles the disk tier.
        session = URLSession(configuration: .default)
    }

    func image(for url: URL) -> UIImage? {
        memoryCache.object(forKey: url as NSURL)
    }

    func loadImage(for url: URL) async throws -> UIImage {
        if let cached = memoryCache.object(forKey: url as NSURL) {
            return cached
        }

        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        let (data, _) = try await session.data(for: request)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        memoryCache.setObject(image, forKey: url as NSURL)
        return image
    }
}
