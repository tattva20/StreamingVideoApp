import Foundation

public final class FileSystemVideoImageDataStore: VideoImageDataStore {
    private let storeURL: URL

    public init(storeURL: URL) {
        self.storeURL = storeURL
    }

    public func insert(_ data: Data, for url: URL) throws {
        do {
            let data = CodableVideoImageData(data: data, url: url)
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: storeURL)
        } catch {
            throw error
        }
    }

    public func retrieve(dataForURL url: URL) throws -> Data? {
        guard let data = try? Data(contentsOf: storeURL) else {
            return nil
        }

        do {
            let decoded = try JSONDecoder().decode(CodableVideoImageData.self, from: data)
            return decoded.url == url ? decoded.data : nil
        } catch {
            throw error
        }
    }

    private struct CodableVideoImageData: Codable {
        let data: Data
        let url: URL
    }
}
