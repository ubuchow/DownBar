import AppKit
import CoreText

// DownBar — 菜单栏一键打开「下载」文件夹

private enum C {
    static let name = "下载"
}

private enum MenuIcon {
    private static let badge: CGFloat = 17.0
    private static let ringWidth: CGFloat = 1.45
    private static let ringColor = NSColor.white

    static func image() -> NSImage {
        let width = badge
        let height = badge
        let image = NSImage(size: NSSize(width: width, height: height))
        for scale in [1, 2, 3] as [CGFloat] {
            let pxW = Int((width * scale).rounded())
            let pxH = Int((height * scale).rounded())
            guard let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: pxW,
                pixelsHigh: pxH,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ) else { continue }
            rep.size = NSSize(width: width, height: height)
            NSGraphicsContext.saveGraphicsState()
            if let ctx = NSGraphicsContext(bitmapImageRep: rep) {
                NSGraphicsContext.current = ctx
                ctx.imageInterpolation = .high
                ctx.shouldAntialias = true
                NSColor.clear.setFill()
                NSRect(x: 0, y: 0, width: width, height: height).fill()
                draw(in: NSRect(x: 0, y: 0, width: width, height: height))
            }
            NSGraphicsContext.restoreGraphicsState()
            image.addRepresentation(rep)
        }
        image.isTemplate = false
        return image
    }

    private static func timesBold(_ size: CGFloat) -> NSFont {
        for name in ["TimesNewRomanPS-BoldMT", "Times New Roman Bold", "Times-Bold", "TimesNewRomanPSMT"] {
            if let f = NSFont(name: name, size: size) { return f }
        }
        return .systemFont(ofSize: size, weight: .bold)
    }

    private static func draw(in rect: NSRect) {
        let badgeY = ((rect.height - badge) * 0.5).rounded()
        let badgeRect = NSRect(x: (rect.width - badge) * 0.5, y: badgeY, width: badge, height: badge)
        drawRing(color: ringColor, badgeRect: badgeRect)
        drawCentered(
            "D",
            font: timesBold(9),
            color: ringColor,
            center: NSPoint(x: badgeRect.midX, y: badgeRect.midY)
        )
    }

    private static func drawRing(color: NSColor, badgeRect: NSRect) {
        let inset = ringWidth * 0.5 + 0.15
        let ring = NSBezierPath(ovalIn: badgeRect.insetBy(dx: inset, dy: inset))
        ring.lineWidth = ringWidth
        ring.lineCapStyle = .round
        ring.lineJoinStyle = .round
        color.setStroke()
        ring.stroke()
    }


    private static func drawCentered(
        _ s: String,
        font: NSFont,
        color: NSColor,
        center: NSPoint
    ) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attrs))
        let ink = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        ctx.textMatrix = .identity
        ctx.textPosition = CGPoint(x: center.x - ink.midX, y: center.y - ink.midY)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var item: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = item.button {
            btn.image = MenuIcon.image()
            btn.imagePosition = .imageOnly
            btn.imageScaling = .scaleNone
            btn.toolTip = "打开下载文件夹"
            btn.target = self
            btn.action = #selector(clicked(_:))
            btn.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func clicked(_ sender: Any?) {
        if let e = NSApp.currentEvent, e.type == .rightMouseUp {
            let m = NSMenu()
            m.addItem(withTitle: "打开下载文件夹", action: #selector(openDownloads), keyEquivalent: "")
            m.addItem(.separator())
            m.addItem(withTitle: "退出 \(C.name)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            item.menu = m
            item.button?.performClick(nil)
            item.menu = nil
            return
        }
        openDownloads()
    }

    @objc private func openDownloads() {
        let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: (NSHomeDirectory() as NSString).appendingPathComponent("Downloads"))
        NSWorkspace.shared.open(url)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
