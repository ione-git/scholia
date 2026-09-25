import XCTest

struct RGBColor: CustomStringConvertible {
    let red: Int
    let green: Int
    let blue: Int

    var description: String { "(\(red), \(green), \(blue))" }

    func isClose(to other: RGBColor) -> Bool {
        max(abs(red - other.red), abs(green - other.green), abs(blue - other.blue)) <= 3
    }
}

extension XCUIScreenshot {
    func color(at normalizedPoint: CGPoint) throws -> RGBColor {
        let image = try XCTUnwrap(image.cgImage)
        let pixel = CGRect(
            x: (normalizedPoint.x * CGFloat(image.width)).rounded(.down),
            y: (normalizedPoint.y * CGFloat(image.height)).rounded(.down), width: 1, height: 1)
        let cropped = try XCTUnwrap(image.cropping(to: pixel))
        let context = try XCTUnwrap(
            CGContext(
                data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let components = try XCTUnwrap(context.data).bindMemory(to: UInt8.self, capacity: 4)
        return RGBColor(red: Int(components[0]), green: Int(components[1]), blue: Int(components[2]))
    }
}
