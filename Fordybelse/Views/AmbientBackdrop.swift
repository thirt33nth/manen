import SwiftUI

struct AmbientBackdrop: View {
    let isActive: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let palette = Palette(colorScheme: colorScheme)

                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.base))

                drawVignette(
                    in: &context,
                    size: size,
                    time: time,
                    color: palette.vignette,
                    opacity: isActive ? 0.13 : 0.08
                )
            }
        }
    }

    private func drawVignette(
        in context: inout GraphicsContext,
        size: CGSize,
        time: TimeInterval,
        color: Color,
        opacity: Double
    ) {
        let center = CGPoint(
            x: size.width * (0.50 + 0.015 * CGFloat(sin(time / 41.0))),
            y: size.height * (0.48 + 0.012 * CGFloat(cos(time / 47.0)))
        )
        let rect = CGRect(
            x: center.x - size.width * 0.46,
            y: center.y - size.height * 0.34,
            width: size.width * 0.92,
            height: size.height * 0.68
        )

        var graphicsContext = context
        graphicsContext.addFilter(.blur(radius: 54))
        graphicsContext.fill(Path(ellipseIn: rect), with: .color(color.opacity(opacity)))
    }
}

private struct Palette {
    let base: Color
    let vignette: Color

    init(colorScheme: ColorScheme) {
        if colorScheme == .dark {
            base = Color(white: 0.035)
            vignette = Color(white: 0.34)
        } else {
            base = Color(white: 0.965)
            vignette = Color(white: 0.62)
        }
    }
}
