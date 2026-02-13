import Foundation
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers

/// Usage:
///   swift strip_png_alpha.swift /path/to/in.png [/path/to/out.png]
///
/// Writes a PNG with the alpha channel removed (flattened onto opaque white).

func die(_ message: String) -> Never {
    fputs("error: \(message)\n", stderr)
    exit(1)
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    die("Missing input path. Example: swift strip_png_alpha.swift input.png output.png")
}

let inputURL = URL(fileURLWithPath: args[1])
let outputURL: URL = {
    if args.count >= 3 {
        return URL(fileURLWithPath: args[2])
    }
    return inputURL
}()

guard let src = CGImageSourceCreateWithURL(inputURL as CFURL, nil) else {
    die("Could not open input image: \(inputURL.path)")
}
guard let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
    die("Could not decode input image: \(inputURL.path)")
}

let width = image.width
let height = image.height

let colorSpace = CGColorSpaceCreateDeviceRGB()
let bytesPerRow = width * 4
let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)

guard let ctx = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: colorSpace,
    bitmapInfo: bitmapInfo.rawValue
) else {
    die("Could not create CGContext")
}

// Fill white background, then draw image on top (alpha composited).
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

guard let outImage = ctx.makeImage() else {
    die("Could not create output CGImage")
}

guard let dest = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    die("Could not create image destination: \(outputURL.path)")
}

CGImageDestinationAddImage(dest, outImage, nil)
guard CGImageDestinationFinalize(dest) else {
    die("Could not write output image: \(outputURL.path)")
}

print("wrote: \(outputURL.path)")

