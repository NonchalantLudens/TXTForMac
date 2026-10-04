import CoreGraphics
import CoreText
import Foundation
import ImageIO

// 生成 DMG 安装窗口背景（660×420，透明底）：标题、提示文字与拖拽箭头。
// 用法: swift scripts/make-dmg-background.swift <输出png路径>

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let width = 660
let height = 420
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

/// 坐标系换算：CG 原点在左下；窗口 y 用左上原点，height - y
func drawLabel(_ text: String, fontSize: CGFloat, y: CGFloat, hex: UInt32, alpha: CGFloat, centered: Bool) {
    let font = CTFontCreateWithName("PingFangSC-Semibold" as CFString, fontSize, nil)
    let attributes = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: color(hex, alpha),
    ] as CFDictionary
    let attributed = CFAttributedStringCreate(nil, text as CFString, attributes)!
    let line = CTLineCreateWithAttributedString(attributed)
    let lineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
    let x = centered ? (CGFloat(width) - lineWidth) / 2 : (CGFloat(width) - lineWidth) / 2
    context.textPosition = CGPoint(x: x, y: CGFloat(height) - y - fontSize)
    CTLineDraw(line, context)
}

// 标题与提示
drawLabel("TXTForMac", fontSize: 30, y: 46, hex: 0x1D1D1F, alpha: 1, centered: true)
drawLabel("把 TXTForMac 拖到右边 Applications 完成安装", fontSize: 16, y: 368, hex: 0x6E6E73, alpha: 1, centered: true)
drawLabel("Drag TXTForMac into Applications to install", fontSize: 12, y: 392, hex: 0xA1A1A6, alpha: 1, centered: true)

// 中间拖拽箭头（从左图标位指向右 Applications 位）
let arrowY = CGFloat(height) - 220
let startX: CGFloat = 246
let endX: CGFloat = 414
context.setStrokeColor(color(0x2F7BF6, 0.85))
context.setLineWidth(10)
context.setLineCap(.round)
context.addLines(between: [CGPoint(x: startX, y: arrowY), CGPoint(x: endX - 26, y: arrowY)])
context.strokePath()
let head = CGMutablePath()
head.move(to: CGPoint(x: endX, y: arrowY))
head.addLine(to: CGPoint(x: endX - 38, y: arrowY + 24))
head.addLine(to: CGPoint(x: endX - 38, y: arrowY - 24))
head.closeSubpath()
context.setFillColor(color(0x2F7BF6, 0.85))
context.addPath(head)
context.fillPath()

// 输出
guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write("用法: swift scripts/make-dmg-background.swift <输出png路径>\n".data(using: .utf8)!)
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

FileHandle.standardOutput.write("DMG 背景已生成\n".data(using: .utf8)!)
