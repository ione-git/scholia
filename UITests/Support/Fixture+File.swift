import XCTest

extension Fixture {
    var file: URL {
        get throws {
            try XCTUnwrap(
                Bundle(for: UITestCase.self).url(forResource: rawValue, withExtension: "epub", subdirectory: "Fixtures")
            )
        }
    }

    var fileInfo: String {
        get throws {
            let size = try XCTUnwrap(try file.resourceValues(forKeys: [.fileSizeKey]).fileSize)
            return "EPUB · \(Int64(size).formatted(.byteCount(style: .file)))"
        }
    }
}
