#if os(macOS)
  import AppKit
  import ImageIO

  enum SVGRenderer {
    /// Renders SVG data into an `NSImage` using CoreGraphics / ImageIO.
    /// Works on macOS 10.15+ where CoreSVG provides native SVG support.
    /// Returns `nil` if the SVG cannot be rendered.
    static func image(fromSVG svgData: Data, size: CGSize? = nil) -> NSImage? {
      guard let source = CGImageSourceCreateWithData(svgData as CFData, nil) else { return nil }

      // Get the intrinsic size from the SVG
      var targetSize = size
      if targetSize == nil {
        if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
          let pixelWidth = properties[kCGImagePropertyPixelWidth as String] as? CGFloat,
          let pixelHeight = properties[kCGImagePropertyPixelHeight as String] as? CGFloat
        {

          targetSize = CGSize(width: pixelWidth, height: pixelHeight)
        }
      }

      guard let targetSize = targetSize else {
        // Fallback: try to create image at default size
        let options: [String: Any] = [
          kCGImageSourceCreateThumbnailFromImageIfAbsent as String: true,
          kCGImageSourceCreateThumbnailWithTransform as String: true,
          kCGImageSourceThumbnailMaxPixelSize as String: 256,
        ]
        guard
          let cgImage = CGImageSourceCreateImageAtIndex(
            source, 0, options as CFDictionary
          )
        else { return nil }

        return NSImage(cgImage: cgImage, size: .zero)
      }

      let maxPixelSize: CGFloat = max(targetSize.width, targetSize.height)
      let options: [String: Any] = [
        kCGImageSourceCreateThumbnailFromImageIfAbsent as String: true,
        kCGImageSourceCreateThumbnailWithTransform as String: true,
        kCGImageSourceThumbnailMaxPixelSize as String: maxPixelSize,
      ]

      guard
        let cgImage = CGImageSourceCreateImageAtIndex(
          source, 0, options as CFDictionary
        )
      else { return nil }

      return NSImage(cgImage: cgImage, size: .zero)
    }
  }
#endif
