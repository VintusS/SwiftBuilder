import CoreGraphics
import Foundation
import ImageIO

enum AppIconGeneratorError: LocalizedError {
    case unreadableImage
    case pngEncodingFailed

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "Could not read the selected image. Choose a valid PNG, JPEG, HEIC, or TIFF file."
        case .pngEncodingFailed:
            return "Could not convert the selected image into an app icon PNG."
        }
    }
}

@MainActor
enum AppIconGenerator {
    static let generatedAppIconName = "SwiftBuilderGeneratedAppIcon"

    private static let iconSize = 1024
    private static let generatedFilenames = [
        "SwiftBuilderPreviewIcon.png",
        "SwiftBuilderPreviewIcon-Dark.png",
        "SwiftBuilderPreviewIcon-Tinted.png"
    ]

    static func writeNormalizedPNG(from sourceURL: URL, to destinationURL: URL) throws {
        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            throw AppIconGeneratorError.unreadableImage
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: iconSize * 2
        ]

        guard let sourceImage = CGImageSourceCreateThumbnailAtIndex(
            imageSource,
            0,
            thumbnailOptions as CFDictionary
        ) else {
            throw AppIconGeneratorError.unreadableImage
        }

        let imageWidth = CGFloat(sourceImage.width)
        let imageHeight = CGFloat(sourceImage.height)
        guard imageWidth > 0, imageHeight > 0 else {
            throw AppIconGeneratorError.unreadableImage
        }

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
            CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        )

        guard let context = CGContext(
            data: nil,
            width: iconSize,
            height: iconSize,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw AppIconGeneratorError.pngEncodingFailed
        }

        let canvas = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        context.fill(canvas)
        context.interpolationQuality = .high

        let scale = max(CGFloat(iconSize) / imageWidth, CGFloat(iconSize) / imageHeight)
        let drawSize = CGSize(width: imageWidth * scale, height: imageHeight * scale)
        let drawRect = CGRect(
            x: (CGFloat(iconSize) - drawSize.width) / 2,
            y: (CGFloat(iconSize) - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        context.draw(sourceImage, in: drawRect)

        guard let outputImage = context.makeImage() else {
            throw AppIconGeneratorError.pngEncodingFailed
        }

        try FileManager.default.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        guard let destination = CGImageDestinationCreateWithURL(
            destinationURL as CFURL,
            "public.png" as CFString,
            1,
            nil
        ) else {
            throw AppIconGeneratorError.pngEncodingFailed
        }

        CGImageDestinationAddImage(destination, outputImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw AppIconGeneratorError.pngEncodingFailed
        }
    }

    static func installPreviewRunnerIcon(from sourceURL: URL, projectPath: String) throws {
        let appIconSetURL = previewRunnerAppIconSetURL(projectPath: projectPath)
        try FileManager.default.createDirectory(at: appIconSetURL, withIntermediateDirectories: true)

        for filename in generatedFilenames {
            try? FileManager.default.removeItem(at: appIconSetURL.appendingPathComponent(filename))
        }

        let primaryIconURL = appIconSetURL.appendingPathComponent(generatedFilenames[0])
        try writeNormalizedPNG(from: sourceURL, to: primaryIconURL)

        for filename in generatedFilenames.dropFirst() {
            let iconURL = appIconSetURL.appendingPathComponent(filename)
            try FileManager.default.copyItem(at: primaryIconURL, to: iconURL)
        }

        try contentsJSONWithGeneratedIcons.write(
            to: appIconSetURL.appendingPathComponent("Contents.json"),
            atomically: true,
            encoding: .utf8
        )
    }

    static func resetPreviewRunnerIcon(projectPath: String) throws {
        let appIconSetURL = previewRunnerAppIconSetURL(projectPath: projectPath)
        try? FileManager.default.removeItem(at: appIconSetURL)
    }

    private static func previewRunnerAppIconSetURL(projectPath: String) -> URL {
        URL(fileURLWithPath: projectPath)
            .appendingPathComponent(
                "PreviewRunner/Assets.xcassets/\(generatedAppIconName).appiconset",
                isDirectory: true
            )
    }

    private static let contentsJSONWithGeneratedIcons = """
    {
      "images" : [
        {
          "filename" : "SwiftBuilderPreviewIcon.png",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        },
        {
          "appearances" : [
            {
              "appearance" : "luminosity",
              "value" : "dark"
            }
          ],
          "filename" : "SwiftBuilderPreviewIcon-Dark.png",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        },
        {
          "appearances" : [
            {
              "appearance" : "luminosity",
              "value" : "tinted"
            }
          ],
          "filename" : "SwiftBuilderPreviewIcon-Tinted.png",
          "idiom" : "universal",
          "platform" : "ios",
          "size" : "1024x1024"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """

}
