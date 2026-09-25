import XCTest

struct RGB: Equatable, CustomStringConvertible {
    let red: Int
    let green: Int
    let blue: Int

    init(red: Int, green: Int, blue: Int) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(hex: String) throws {
        let value = try XCTUnwrap(Int(hex.dropFirst(), radix: 16), hex)
        self.init(red: value >> 16 & 0xff, green: value >> 8 & 0xff, blue: value & 0xff)
    }

    var description: String { String(format: "#%02x%02x%02x", red, green, blue) }

    func distance(to other: RGB) -> Int {
        max(abs(red - other.red), abs(green - other.green), abs(blue - other.blue))
    }
}

struct ScreenPixels {
    private let bytes: [UInt8]
    private let width: Int
    private let height: Int
    private let scale: CGFloat

    init(_ screenshot: XCUIScreenshot, pointWidth: CGFloat) throws {
        let image = try XCTUnwrap(screenshot.image.cgImage)
        width = image.width
        height = image.height
        scale = CGFloat(image.width) / pointWidth
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let context = try XCTUnwrap(
            CGContext(
                data: &bytes, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        self.bytes = bytes
    }

    func color(at point: CGPoint) -> RGB {
        pixel(x: Int(point.x * scale), y: Int(point.y * scale))
    }

    func colors(in rect: CGRect) -> [RGB] {
        var colors: [RGB] = []
        for y in Int(rect.minY * scale)..<Int(rect.maxY * scale) {
            for x in Int(rect.minX * scale)..<Int(rect.maxX * scale) {
                colors.append(pixel(x: x, y: y))
            }
        }
        return colors
    }

    private func pixel(x: Int, y: Int) -> RGB {
        let offset = (y * width + x) * 4
        return RGB(red: Int(bytes[offset]), green: Int(bytes[offset + 1]), blue: Int(bytes[offset + 2]))
    }
}
