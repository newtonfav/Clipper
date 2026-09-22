import Foundation

/// Reads and writes the single JSON file that holds every clip.
struct ClipFileStorage: Sendable {
    let url: URL

    /// Uses the App Group container. If the group is misconfigured, falls back to the
    /// process's own Documents directory so the app keeps working (without sharing).
    init(directory: URL? = nil, fileName: String = AppGroup.clipsFileName) {
        let base = directory
            ?? AppGroup.containerURL
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = base.appendingPathComponent(fileName)
    }

    func read() throws -> ClipFile {
        guard FileManager.default.fileExists(atPath: url.path) else { return ClipFile() }
        let data = try Data(contentsOf: url)
        return try Self.decoder.decode(ClipFile.self, from: data)
    }

    func write(_ file: ClipFile) throws {
        let data = try Self.encoder.encode(file)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
