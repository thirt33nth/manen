import SwiftUI

struct GenerativeAnimationStage: View {
    let isActive: Bool
    let mode: FocusMode
    let productivityCueStartedAt: Date?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard isActive else { return }

                let time = timeline.date.timeIntervalSinceReferenceDate
                let palette = StagePalette(colorScheme: colorScheme)

                drawAtmosphericGrain(time: time, size: size, palette: palette, context: &context)

                switch mode {
                case .focus:
                    for index in 0..<30 {
                        drawRectElement(index: index, time: time, size: size, palette: palette, context: &context)
                    }
                case .relax:
                    for index in 0..<26 {
                        drawCircleElement(index: index, time: time, size: size, palette: palette, context: &context)
                    }
                case .sleep:
                    for index in 0..<12 {
                        drawWaveElement(index: index, time: time, size: size, palette: palette, context: &context)
                    }
                }

                if mode == .focus, let productivityCueStartedAt {
                    let cueAge = timeline.date.timeIntervalSince(productivityCueStartedAt)
                    drawProductivityCue(age: cueAge, size: size, palette: palette, context: &context)
                }
            }
        }
        .opacity(isActive ? 1 : 0)
        .animation(.easeOut(duration: 1.15), value: isActive)
        .accessibilityHidden(true)
    }

    private func drawAtmosphericGrain(
        time: TimeInterval,
        size: CGSize,
        palette: StagePalette,
        context: inout GraphicsContext
    ) {
        var graphicsContext = context
        graphicsContext.opacity = 0.018

        for index in 0..<42 {
            let seed = Double(index) * 13.701
            let shimmer = 0.45 + 0.55 * sin(time / (11.0 + random(seed + 1.0) * 12.0) + seed)
            let x = size.width * CGFloat(random(seed + 2.0))
            let y = size.height * CGFloat(random(seed + 3.0))
            let side = CGFloat(0.55 + random(seed + 4.0) * 1.45)
            let rect = CGRect(x: x, y: y, width: side, height: side)

            var pointContext = graphicsContext
            pointContext.opacity = shimmer * 0.025
            pointContext.fill(Path(ellipseIn: rect), with: .color(palette.stroke))
        }
    }

    private func drawProductivityCue(
        age: TimeInterval,
        size: CGSize,
        palette: StagePalette,
        context: inout GraphicsContext
    ) {
        let duration = 7.5
        guard age >= 0, age <= duration else { return }

        let progress = age / duration
        let appear = smoothstep(0.0, 0.18, progress)
        let dissolve = 1.0 - smoothstep(0.48, 1.0, progress)
        let alpha = appear * dissolve

        guard alpha > 0.01 else { return }

        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.50)
        let base = min(size.width, size.height)
        let pulse = CGFloat(0.72 + progress * 0.72)

        for index in 0..<4 {
            let seed = Double(index) * 17.37
            let width = base * CGFloat(0.22 + Double(index) * 0.075) * pulse
            let height = base * CGFloat(0.14 + Double(index) * 0.055) * pulse
            let offsetY = base * CGFloat(random(seed + 1.0) - 0.5) * 0.06
            let rect = CGRect(
                x: center.x - width / 2,
                y: center.y - height / 2 + offsetY,
                width: width,
                height: height
            )

            var graphicsContext = context
            graphicsContext.opacity = alpha * (0.20 - Double(index) * 0.025)
            graphicsContext.addFilter(.blur(radius: CGFloat(index) * 0.18))
            graphicsContext.stroke(
                Path(roundedRect: rect, cornerRadius: max(2, min(width, height) * 0.035)),
                with: .color(palette.stroke),
                lineWidth: 0.52
            )
        }

        let markSize = base * CGFloat(0.048 + progress * 0.012)
        let markRect = CGRect(
            x: center.x - markSize / 2,
            y: center.y - markSize / 2,
            width: markSize,
            height: markSize
        )

        var markContext = context
        markContext.opacity = alpha * 0.28
        markContext.stroke(
            Path(roundedRect: markRect, cornerRadius: markSize * 0.12),
            with: .color(palette.stroke),
            lineWidth: 0.7
        )
    }

    private func drawRectElement(
        index: Int,
        time: TimeInterval,
        size: CGSize,
        palette: StagePalette,
        context: inout GraphicsContext
    ) {
        let seed = Double(index) * 19.917
        let layer = index % 3
        let layerDepth = CGFloat(layer) / 2.0
        let lifetime = 10.5 + random(seed + 1.0) * 11.0
        let phase = positiveRemainder(time * (0.42 + random(seed + 2.0) * 0.22) + seed, lifetime) / lifetime
        let fadeIn = smoothstep(0.0, 0.22, phase)
        let fadeOut = 1.0 - smoothstep(0.68, 1.0, phase)
        let alpha = fadeIn * fadeOut

        guard alpha > 0.01 else { return }

        let columns: [CGFloat] = [0.16, 0.32, 0.50, 0.68, 0.84]
        let rows: [CGFloat] = [0.14, 0.30, 0.47, 0.64, 0.82]
        let column = columns[index % columns.count]
        let row = rows[(index / columns.count + Int(random(seed + 3.0) * 4.0)) % rows.count]
        let offsetX = CGFloat(random(seed + 4.0) - 0.5) * size.width * 0.12
        let offsetY = CGFloat(random(seed + 5.0) - 0.5) * size.height * 0.12
        let drift = CGFloat((phase - 0.5) * (0.025 + random(seed + 6.0) * 0.040))
        let x = size.width * column + offsetX + size.width * drift
        let y = size.height * row + offsetY - size.height * drift * 0.45
        let base = min(size.width, size.height)
        let radius = base * CGFloat(0.010 + random(seed + 7.0) * 0.032) * (0.74 + layerDepth * 0.34)
        let breathing = 0.88 + 0.12 * sin(time / (7.0 + random(seed + 8.0) * 7.0) + seed)
        let scale = CGFloat((0.70 + phase * (0.42 + random(seed + 9.0) * 0.32)) * breathing)
        let rotation = seed * 0.03 + time / (36.0 + random(seed + 10.0) * 42.0)

        var graphicsContext = context
        graphicsContext.opacity = alpha * (0.12 + layerDepth * 0.11 + random(seed + 11.0) * 0.12)
        graphicsContext.addFilter(.blur(radius: 0.05 + CGFloat(1.0 - layerDepth) * 0.35))

        let rect = CGRect(
            x: x - radius * scale,
            y: y - radius * scale,
            width: radius * scale * 2,
            height: radius * scale * 2
        )

        let aspect = index.isMultiple(of: 3) ? CGFloat(1.0 + random(seed + 12.0) * 1.15) : 1.0
        let focusRect = CGRect(
            x: x - rect.width * aspect / 2,
            y: y - rect.height / 2,
            width: rect.width * aspect,
            height: rect.height
        )
        let path = Path(roundedRect: focusRect, cornerRadius: min(focusRect.width, focusRect.height) * 0.08)

        graphicsContext.translateBy(x: x, y: y)
        graphicsContext.rotate(by: .radians(rotation * 0.18))
        graphicsContext.translateBy(x: -x, y: -y)

        graphicsContext.stroke(path, with: .color(palette.stroke), lineWidth: 0.45 + CGFloat(random(seed + 13.0)) * 0.32)
    }

    private func drawCircleElement(
        index: Int,
        time: TimeInterval,
        size: CGSize,
        palette: StagePalette,
        context: inout GraphicsContext
    ) {
        let seed = Double(index) * 23.311
        let layer = index % 3
        let layerDepth = CGFloat(layer) / 2.0
        let lifetime = 11.0 + random(seed + 1.0) * 12.0
        let phase = positiveRemainder(time * (0.36 + random(seed + 2.0) * 0.18) + seed, lifetime) / lifetime
        let alpha = smoothstep(0.0, 0.24, phase) * (1.0 - smoothstep(0.66, 1.0, phase))

        guard alpha > 0.01 else { return }

        let centerX = size.width * 0.5
        let centerY = size.height * 0.48
        let orbit = phase * .pi * 2.0 + seed
        let reachX = size.width * CGFloat(0.12 + random(seed + 3.0) * 0.40)
        let reachY = size.height * CGFloat(0.08 + random(seed + 4.0) * 0.36)
        let orbitalX = CGFloat(cos(orbit * (0.28 + random(seed + 5.0) * 0.18)))
        let orbitalY = CGFloat(sin(orbit * (0.24 + random(seed + 7.0) * 0.16)))
        let x = centerX + orbitalX * reachX + CGFloat(random(seed + 6.0) - 0.5) * size.width * 0.15
        let y = centerY + orbitalY * reachY + CGFloat(random(seed + 8.0) - 0.5) * size.height * 0.12
        let base = min(size.width, size.height)
        let radius = base * CGFloat(0.012 + random(seed + 9.0) * 0.040) * (0.78 + layerDepth * 0.38)
        let breath = 0.86 + 0.20 * sin(time / (5.8 + random(seed + 10.0) * 8.0) + seed)
        let scale = CGFloat((0.70 + phase * (0.62 + random(seed + 11.0) * 0.36)) * breath)

        var graphicsContext = context
        graphicsContext.opacity = alpha * (0.11 + layerDepth * 0.10 + random(seed + 12.0) * 0.13)
        graphicsContext.addFilter(.blur(radius: 0.10 + CGFloat(1.0 - layerDepth) * 0.42))

        let rect = CGRect(
            x: x - radius * scale,
            y: y - radius * scale,
            width: radius * scale * 2,
            height: radius * scale * 2
        )

        graphicsContext.stroke(
            Path(ellipseIn: rect),
            with: .color(palette.stroke),
            lineWidth: 0.45 + CGFloat(random(seed + 13.0)) * 0.34
        )

        if index.isMultiple(of: 5) {
            let innerScale = CGFloat(0.42 + random(seed + 14.0) * 0.22)
            let innerRect = rect.insetBy(dx: rect.width * innerScale, dy: rect.height * innerScale)
            graphicsContext.opacity *= 0.54
            graphicsContext.stroke(Path(ellipseIn: innerRect), with: .color(palette.stroke), lineWidth: 0.38)
        }
    }

    private func drawWaveElement(
        index: Int,
        time: TimeInterval,
        size: CGSize,
        palette: StagePalette,
        context: inout GraphicsContext
    ) {
        let seed = Double(index) * 31.071
        let layer = index % 3
        let layerDepth = CGFloat(layer) / 2.0
        let lifetime = 14.0 + random(seed + 1.0) * 16.0
        let phase = positiveRemainder(time * (0.26 + random(seed + 2.0) * 0.12) + seed, lifetime) / lifetime
        let alpha = smoothstep(0.0, 0.22, phase) * (1.0 - smoothstep(0.70, 1.0, phase))

        guard alpha > 0.01 else { return }

        let band = CGFloat(index) / 11.0
        let baseline = size.height * (0.18 + band * 0.64) + CGFloat(random(seed + 3.0) - 0.5) * size.height * 0.08
        let amplitude = size.height * CGFloat(0.006 + random(seed + 4.0) * 0.030) * CGFloat(0.78 + phase * 0.42)
        let frequency = 0.78 + random(seed + 5.0) * 1.45
        let horizontalDrift = size.width * CGFloat((phase - 0.5) * (0.09 + random(seed + 6.0) * 0.10))

        var path = Path()
        let steps = 72
        for step in 0...steps {
            let progress = Double(step) / Double(steps)
            let x = CGFloat(progress) * size.width + horizontalDrift
            let primary = sin(progress * .pi * 2.0 * frequency + time / (8.5 + random(seed + 7.0) * 8.0) + seed)
            let secondary = sin(progress * .pi * 2.0 * (frequency * 0.42) + time / (14.0 + random(seed + 8.0) * 10.0) + seed * 0.4)
            let edgeFade = smoothstep(0.0, 0.12, progress) * (1.0 - smoothstep(0.88, 1.0, progress))
            let y = baseline + CGFloat(primary * 0.72 + secondary * 0.28) * amplitude * CGFloat(edgeFade)

            if step == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        var graphicsContext = context
        graphicsContext.opacity = alpha * (0.08 + layerDepth * 0.10 + random(seed + 9.0) * 0.12)
        graphicsContext.addFilter(.blur(radius: 0.18 + CGFloat(1.0 - layerDepth) * 0.68))
        graphicsContext.stroke(
            path,
            with: .color(palette.stroke),
            style: StrokeStyle(lineWidth: 0.42 + CGFloat(random(seed + 10.0)) * 0.36, lineCap: .round, lineJoin: .round)
        )
    }

    private func random(_ seed: Double) -> Double {
        let value = sin(seed * 12.9898) * 43758.5453
        return value - floor(value)
    }

    private func positiveRemainder(_ value: Double, _ divisor: Double) -> Double {
        let result = value.truncatingRemainder(dividingBy: divisor)
        return result >= 0 ? result : result + divisor
    }

    private func smoothstep(_ edge0: Double, _ edge1: Double, _ value: Double) -> Double {
        let x = min(max((value - edge0) / (edge1 - edge0), 0), 1)
        return x * x * (3 - 2 * x)
    }
}

private struct StagePalette {
    let stroke: Color

    init(colorScheme: ColorScheme) {
        if colorScheme == .dark {
            stroke = Color(white: 0.88)
        } else {
            stroke = Color(white: 0.08)
        }
    }
}
