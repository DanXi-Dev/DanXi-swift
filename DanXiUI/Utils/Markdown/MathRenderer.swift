import Foundation
import MathJaxSwift
import SwiftDraw
import UIKit

struct RenderedMath {
    let image: UIImage
    let baseline: CGFloat
}

/// A single executor owns JavaScriptCore, conversion and rasterization. Nothing waits on it
/// synchronously from a View body. No UIKit views or live trait collections are used here.
actor MathRenderer {
    static let shared = MathRenderer()
    private var engine: MathJax?
    private var svgCache: [MathExpression: String] = [:]
    private var svgOrder: [MathExpression] = []
    private var svgBytes = 0
    private let images = NSCache<NSString, CachedImage>()

    private final class CachedImage {
        let value: RenderedMath
        init(_ value: RenderedMath) { self.value = value }
    }

    private init() {
        images.totalCostLimit = 32 * 1024 * 1024
        images.countLimit = 256
    }

    func preload(_ expressions: [MathExpression]) {
        // SVGs are independent of display scale, theme and Dynamic Type.
        for expression in expressions {
            guard !Task.isCancelled else { return }
            _ = try? svg(for: expression)
        }
    }

    func render(_ expression: MathExpression, fontSize: CGFloat,
                displayScale: CGFloat, dark: Bool) throws -> RenderedMath {
        try Task.checkCancellation()
        let key = "\(expression.url.absoluteString)|\(fontSize)|\(displayScale)|\(dark)" as NSString
        if let cached = images.object(forKey: key) { return cached.value }
        let raw = try svg(for: expression)
        let geometry = try MathSVGGeometry(raw)
        let xHeight = UIFont.systemFont(ofSize: fontSize).xHeight
        let size = CGSize(width: geometry.width * xHeight, height: geometry.height * xHeight)
        // Bound texture allocations, including pathological but valid TeX.
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0,
              size.width <= 16_384, size.height <= 4096,
              size.width * size.height * displayScale * displayScale <= 8_000_000 else {
            throw MathRenderError.tooLarge
        }
        // Resolve only inherited currentColor. Explicit TeX fill/stroke colors are preserved.
        var svg = raw
        svg.replaceSubrange(geometry.rootRange, with: geometry.root
            .replacingOccurrences(of: geometry.widthAttribute, with: "width=\"\(size.width)\"")
            .replacingOccurrences(of: geometry.heightAttribute, with: "height=\"\(size.height)\"")
            .replacingOccurrences(of: "<svg ", with: "<svg color=\"\(dark ? "#ffffff" : "#000000")\" "))
        guard let drawing = SwiftDraw.SVG(data: Data(svg.utf8)) else {
            throw MathRenderError.invalidSVG
        }
        let image = drawing.rasterize(size: size, scale: displayScale)
        let rendered = RenderedMath(image: image.withRenderingMode(.alwaysOriginal),
                                    baseline: geometry.baseline * xHeight)
        images.setObject(CachedImage(rendered), forKey: key,
                         cost: Int(size.width * size.height * displayScale * displayScale * 4))
        return rendered
    }

    private func svg(for expression: MathExpression) throws -> String {
        if let cached = svgCache[expression] { return cached }
        guard expression.tex.utf8.count <= 16_384 else { throw MathRenderError.tooLarge }
        if engine == nil { engine = try MathJax(preferredOutputFormat: .svg) }
        let input = TeXInputProcessorOptions()
        input.loadPackages = TeXInputProcessorOptions.Packages.all.filter {
            !["noerrors", "noundefined", "html"].contains($0)
        }
        let output = SVGOutputProcessorOptions(fontCache: SVGOutputProcessorOptions.FontCaches.none,
                                               internalSpeechTitles: false,
                                               unknownFamily: "Helvetica")
        let result = try engine!.tex2svg(expression.tex, styles: false,
                                       conversionOptions: ConversionOptions(display: expression.display),
                                       inputOptions: input, outputOptions: output)
        guard !result.contains("data-mml-node=\"merror\"") else { throw MathRenderError.invalidTeX }
        let bytes = result.utf8.count
        while !svgOrder.isEmpty && (svgOrder.count >= 256 || svgBytes + bytes > 8 * 1024 * 1024) {
            let oldest = svgOrder.removeFirst()
            svgBytes -= svgCache.removeValue(forKey: oldest)?.utf8.count ?? 0
        }
        if bytes <= 8 * 1024 * 1024 {
            svgOrder.append(expression)
            svgCache[expression] = result
            svgBytes += bytes
        }
        return result
    }
}

enum MathRenderError: Error { case invalidSVG, invalidTeX, tooLarge }

/// MathJax reports dimensions and vertical-align in ex units; the latter is negative
/// for descenders and must also be applied to inline Text attachments.
struct MathSVGGeometry {
    let rootRange: Range<String.Index>
    let root: String
    let widthAttribute: String
    let heightAttribute: String
    let width: CGFloat
    let height: CGFloat
    let baseline: CGFloat

    init(_ svg: String) throws {
        guard let range = svg.range(of: #"<svg\b[^>]*>"#, options: .regularExpression) else {
            throw MathRenderError.invalidSVG
        }
        rootRange = range
        let root = String(svg[range])
        self.root = root
        func attribute(_ name: String) throws -> (String, CGFloat) {
            let regex = try NSRegularExpression(pattern: "\\b" + name + "=\"([0-9.eE+-]+)ex\"")
            guard let match = regex.firstMatch(in: root, range: NSRange(root.startIndex..., in: root)),
                  let whole = Range(match.range, in: root), let value = Range(match.range(at: 1), in: root),
                  let number = Double(root[value]) else { throw MathRenderError.invalidSVG }
            return (String(root[whole]), CGFloat(number))
        }
        let w = try attribute("width")
        let h = try attribute("height")
        widthAttribute = w.0
        width = w.1
        heightAttribute = h.0
        height = h.1
        let regex = try NSRegularExpression(pattern: #"vertical-align:\s*([0-9.eE+-]+)ex"#)
        if let match = regex.firstMatch(in: root, range: NSRange(root.startIndex..., in: root)),
           let value = Range(match.range(at: 1), in: root), let number = Double(root[value]) {
            baseline = CGFloat(number)
        } else { baseline = 0 }
    }
}
