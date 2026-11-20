import AppKit
import CoreGraphics
import PomoPetCore
import SwiftUI

public enum PixelImageRenderer {
    public static func cgImage(from frame: PixelFrame, scale: Int = 2) -> CGImage? {
        let width = frame.width * max(1, scale)
        let height = frame.height * max(1, scale)
        var bytes = [UInt8](repeating: 0, count: width * height * 4)

        for y in 0..<frame.height {
            for x in 0..<frame.width {
                let px = frame.pixels[y * frame.width + x]
                for sy in 0..<scale {
                    for sx in 0..<scale {
                        let outX = x * scale + sx
                        let outY = y * scale + sy
                        let offset = (outY * width + outX) * 4
                        bytes[offset] = px.r
                        bytes[offset + 1] = px.g
                        bytes[offset + 2] = px.b
                        bytes[offset + 3] = px.a
                    }
                }
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    public static func menuBarImage(from frame: PixelFrame, pointSize: CGFloat = 18) -> NSImage? {
        guard let cg = cgImage(from: frame, scale: 2) else { return nil }
        let image = NSImage(cgImage: cg, size: NSSize(width: pointSize, height: pointSize))
        image.isTemplate = false
        return image
    }

    public static func swiftUIImage(from frame: PixelFrame, scale: Int = 4) -> Image? {
        guard let cg = cgImage(from: frame, scale: scale) else { return nil }
        return Image(decorative: cg, scale: 1.0, orientation: .up)
    }
}
