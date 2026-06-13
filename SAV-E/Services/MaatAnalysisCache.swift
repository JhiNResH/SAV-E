import Foundation

/// Lightweight disk cache for `MaatPlaceAnalysisResponse` keyed by place id so
/// the insights panel can render the last-known analysis instantly across app
/// launches while a fresh copy is fetched in the background.
final class MaatAnalysisCache {
    static let shared = MaatAnalysisCache()

    private let fileManager: FileManager
    private let directoryName = "maat-analysis-cache"
    private let queue = DispatchQueue(label: "com.save.maat-analysis-cache", attributes: .concurrent)

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func analysis(for placeId: UUID) -> MaatPlaceAnalysisResponse? {
        queue.sync {
            guard let url = fileURL(for: placeId),
                  let data = try? Data(contentsOf: url),
                  let value = try? JSONDecoder().decode(MaatPlaceAnalysisResponse.self, from: data)
            else { return nil }
            return value
        }
    }

    func store(_ analysis: MaatPlaceAnalysisResponse, for placeId: UUID) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self,
                  let directory = self.directoryURL(),
                  let url = self.fileURL(for: placeId)
            else { return }
            try? self.fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            guard let data = try? JSONEncoder().encode(analysis) else { return }
            try? data.write(to: url, options: [.atomic])
        }
    }

    private func directoryURL() -> URL? {
        fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(directoryName, isDirectory: true)
    }

    private func fileURL(for placeId: UUID) -> URL? {
        directoryURL()?.appendingPathComponent("\(placeId.uuidString).json")
    }
}
