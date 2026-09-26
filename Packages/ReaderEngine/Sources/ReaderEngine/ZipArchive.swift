import Compression
import Foundation

nonisolated struct ZipArchive {
    private struct Entry {
        let method: UInt16
        let compressedSize: Int
        let size: Int
        let headerOffset: Int
    }

    private enum Signature {
        static let endOfDirectory: UInt32 = 0x0605_4b50
        static let directoryEntry: UInt32 = 0x0201_4b50
        static let localHeader: UInt32 = 0x0403_4b50
    }

    private enum Method {
        static let stored: UInt16 = 0
        static let deflated: UInt16 = 8
    }

    private static let endOfDirectorySize = 22
    private static let maximumCommentSize = Int(UInt16.max)
    private static let directoryEntrySize = 46
    private static let localHeaderSize = 30
    private static let utf8NameFlag: UInt16 = 0x0800

    private let data: Data
    private let entries: [String: Entry]

    init?(url: URL) {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe),
            let entries = Self.readDirectory(of: data)
        else { return nil }
        self.data = data
        self.entries = entries
    }

    func contains(_ path: String) -> Bool {
        entries[path] != nil
    }

    func contents(of path: String) -> Data? {
        guard let entry = entries[path],
            data.uint32(at: entry.headerOffset) == Signature.localHeader,
            let nameLength = data.uint16(at: entry.headerOffset + 26),
            let extraLength = data.uint16(at: entry.headerOffset + 28)
        else { return nil }
        let start = entry.headerOffset + Self.localHeaderSize + Int(nameLength) + Int(extraLength)
        guard start + entry.compressedSize <= data.count else { return nil }
        let stored = data.subdata(in: start..<start + entry.compressedSize)
        switch entry.method {
        case Method.stored: return stored
        case Method.deflated: return Self.inflate(stored, size: entry.size)
        default: return nil
        }
    }

    private static func readDirectory(of data: Data) -> [String: Entry]? {
        guard data.count >= endOfDirectorySize else { return nil }
        let lowest = max(0, data.count - endOfDirectorySize - maximumCommentSize)
        guard
            let end = stride(from: data.count - endOfDirectorySize, through: lowest, by: -1).first(where: {
                data.uint32(at: $0) == Signature.endOfDirectory
            }),
            let count = data.uint16(at: end + 10),
            let directoryOffset = data.uint32(at: end + 16)
        else { return nil }
        var entries: [String: Entry] = [:]
        var offset = Int(directoryOffset)
        for _ in 0..<count {
            guard data.uint32(at: offset) == Signature.directoryEntry,
                let flags = data.uint16(at: offset + 8),
                let method = data.uint16(at: offset + 10),
                let compressedSize = data.uint32(at: offset + 20),
                let size = data.uint32(at: offset + 24),
                let nameLength = data.uint16(at: offset + 28),
                let extraLength = data.uint16(at: offset + 30),
                let commentLength = data.uint16(at: offset + 32),
                let headerOffset = data.uint32(at: offset + 42)
            else { return nil }
            let nameStart = offset + directoryEntrySize
            guard nameStart + Int(nameLength) <= data.count else { return nil }
            let nameBytes = data.subdata(in: nameStart..<nameStart + Int(nameLength))
            let isUTF8 = flags & utf8NameFlag != 0
            guard let name = String(data: nameBytes, encoding: isUTF8 ? .utf8 : .isoLatin1) else { return nil }
            entries[name] = Entry(
                method: method, compressedSize: Int(compressedSize), size: Int(size), headerOffset: Int(headerOffset))
            offset = nameStart + Int(nameLength) + Int(extraLength) + Int(commentLength)
        }
        return entries
    }

    private static func inflate(_ compressed: Data, size: Int) -> Data? {
        guard size > 0 else { return Data() }
        var output = Data(count: size)
        let written = output.withUnsafeMutableBytes { destination in
            compressed.withUnsafeBytes { source in
                guard let destination = destination.bindMemory(to: UInt8.self).baseAddress,
                    let source = source.bindMemory(to: UInt8.self).baseAddress
                else { return 0 }
                return compression_decode_buffer(destination, size, source, compressed.count, nil, COMPRESSION_ZLIB)
            }
        }
        return written == size ? output : nil
    }
}

extension Data {
    nonisolated fileprivate func uint16(at offset: Int) -> UInt16? {
        guard offset >= 0, offset + 2 <= count else { return nil }
        return withUnsafeBytes { UInt16(littleEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt16.self)) }
    }

    nonisolated fileprivate func uint32(at offset: Int) -> UInt32? {
        guard offset >= 0, offset + 4 <= count else { return nil }
        return withUnsafeBytes { UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self)) }
    }
}
