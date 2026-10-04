import CoreGraphics
import Foundation
import ImageIO

// 生成 TXTForMac 应用图标（1024×1024）：macOS 圆角方形 + 文档纸张 + 折角 + 文本行。
// 用法: swift scripts/make-icon.swift <输出png路径>

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let size = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

// MARK: 1. 背景圆角方形（含投影）

let backgroundRect = CGRect(x: 100, y: 96, width: 824, height: 824)
let cornerRadius: CGFloat = 184

context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -26), blur: 46, color: color(0x1B4FC4, 0.38))
context.setFillColor(color(0x2F7BF6))
context.addPath(CGPath(
    roundedRect: backgroundRect,
    cornerWidth: cornerRadius,
    cornerHeight: cornerRadius,
    transform: nil
))
context.fillPath()
context.restoreGState()

context.saveGState()
context.addPath(CGPath(
    roundedRect: backgroundRect,
    cornerWidth: cornerRadius,
    cornerHeight: cornerRadius,
    transform: nil
))
context.clip()
let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(0x58A0FF), color(0x2065E0)] as CFArray,
    locations: [0, 1]
)!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 512, y: 920),
    end: CGPoint(x: 512, y: 96),
    options: []
)
/// 顶部柔和高光，增强立体感（无分割线）
let gloss = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(0xFFFFFF, 0.22), color(0xFFFFFF, 0.0)] as CFArray,
    locations: [0, 1]
)!
context.drawLinearGradient(
    gloss,
    start: CGPoint(x: 512, y: 920),
    end: CGPoint(x: 512, y: 320),
    options: []
)
// 内描边
context.setStrokeColor(color(0xFFFFFF, 0.22))
context.setLineWidth(6)
context.addPath(CGPath(
    roundedRect: backgroundRect.insetBy(dx: 5, dy: 5),
    cornerWidth: cornerRadius - 5,
    cornerHeight: cornerRadius - 5,
    transform: nil
))
context.strokePath()
context.restoreGState()

// MARK: 2. 文档纸张（右上折角）

let fold: CGFloat = 104
let documentRect = CGRect(x: 308, y: 204, width: 408, height: 580)
let documentCornerRadius: CGFloat = 26

func documentPath(in rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - documentCornerRadius))
    path.addArc(
        tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
        tangent2End: CGPoint(x: rect.minX + documentCornerRadius, y: rect.maxY),
        radius: documentCornerRadius
    )
    path.addLine(to: CGPoint(x: rect.maxX - fold, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - fold))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + documentCornerRadius))
    path.addArc(
        tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
        tangent2End: CGPoint(x: rect.maxX - documentCornerRadius, y: rect.minY),
        radius: documentCornerRadius
    )
    path.addLine(to: CGPoint(x: rect.minX + documentCornerRadius, y: rect.minY))
    path.addArc(
        tangent1End: CGPoint(x: rect.minX, y: rect.minY),
        tangent2End: CGPoint(x: rect.minX, y: rect.minY + documentCornerRadius),
        radius: documentCornerRadius
    )
    path.closeSubpath()
    return path
}

// 纸张投影
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -14), blur: 30, color: color(0x0B3A9E, 0.30))
context.setFillColor(color(0xFFFFFF))
context.addPath(documentPath(in: documentRect))
context.fillPath()
context.restoreGState()

// 纸张右侧淡灰渐变，呈现纸张厚度
context.saveGState()
context.addPath(documentPath(in: documentRect))
context.clip()
let paperGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [color(0xFFFFFF), color(0xE9EDF4)] as CFArray,
    locations: [0, 1]
)!
context.drawLinearGradient(
    paperGradient,
    start: CGPoint(x: documentRect.minX, y: documentRect.maxY),
    end: CGPoint(x: documentRect.maxX, y: documentRect.minY),
    options: []
)
context.restoreGState()

// 折角
context.saveGState()
let foldTriangle = CGMutablePath()
foldTriangle.move(to: CGPoint(x: documentRect.maxX - fold, y: documentRect.maxY))
foldTriangle.addLine(to: CGPoint(x: documentRect.maxX - fold, y: documentRect.maxY - fold))
foldTriangle.addLine(to: CGPoint(x: documentRect.maxX, y: documentRect.maxY - fold))
foldTriangle.closeSubpath()
context.setFillColor(color(0xC9D3E3))
context.addPath(foldTriangle)
context.fillPath()
context.restoreGState()

// MARK: 3. 文本行（首行标题加粗、末行主题色）

let lineX = documentRect.minX + 52
let lineHeight: CGFloat = 26
let lineCornerRadius: CGFloat = 13
var lineY = documentRect.maxY - fold - 92
let lineSpecs: [(widthRatio: CGFloat, hex: UInt32)] = [
    (0.62, 0x3A4356),
    (0.82, 0xC3CBD9),
    (0.74, 0xC3CBD9),
    (0.86, 0xC3CBD9),
    (0.52, 0xC3CBD9),
    (0.34, 0x2F7BF6),
]
for spec in lineSpecs {
    let lineRect = CGRect(x: lineX, y: lineY, width: (documentRect.width - 104) * spec.widthRatio, height: lineHeight)
    context.setFillColor(color(spec.hex))
    context.addPath(CGPath(
        roundedRect: lineRect,
        cornerWidth: lineCornerRadius,
        cornerHeight: lineCornerRadius,
        transform: nil
    ))
    context.fillPath()
    lineY -= 64
}

// MARK: 输出 PNG

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write("用法: swift scripts/make-icon.swift <输出png路径>\n".data(using: .utf8)!)
    exit(1)
}

let image = context.makeImage()!
let outputURL = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
let destination = CGImageDestinationCreateWithURL(outputURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    FileHandle.standardError.write("PNG 写入失败\n".data(using: .utf8)!)
    exit(1)
}

FileHandle.standardOutput.write("图标已生成: \(CommandLine.arguments[1])\n".data(using: .utf8)!)
