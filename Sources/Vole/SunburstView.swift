import AppKit
import SwiftUI

struct SunburstView: View {
    @EnvironmentObject private var model: DiskModel

    var body: some View {
        let segments = model.segments
        let hovered = model.hovered
        let focus = model.focus
        let inTrail = model.trail.count > 1

        GeometryReader { geo in
            let g = Geometry(size: geo.size)
            ZStack {
                Canvas { context, _ in
                    for segment in segments {
                        let path = wedge(segment, g)
                        let isHot = segment.node === hovered
                        context.fill(path, with: .color(color(for: segment)))
                        context.stroke(
                            path,
                            with: .color(isHot ? .white : Color(nsColor: .windowBackgroundColor)),
                            lineWidth: isHot ? 2 : 1
                        )
                    }
                }

                hub(g, focus: focus, hovered: hovered, canGoUp: inTrail)
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { value in
                    tap(at: value.location, g, segments: segments)
                }
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let point):
                    model.hovered = node(at: point, g, segments: segments)
                case .ended:
                    model.hovered = nil
                }
            }
        }
        .padding(12)
    }

    // MARK: Drawing

    private func color(for segment: Segment) -> Color {
        Color(
            hue: segment.hue / 360,
            saturation: 0.6,
            brightness: 0.92 - Double(segment.depth) * 0.07
        )
    }

    private func wedge(_ segment: Segment, _ g: Geometry) -> Path {
        let r0 = g.hub + CGFloat(segment.depth) * g.ring + 1.5
        let r1 = g.hub + CGFloat(segment.depth + 1) * g.ring - 1.5
        let span = segment.end - segment.start
        let steps = max(2, Int(span * Double(r1) / 2))

        var path = Path()
        for i in 0...steps {
            let point = g.point(r1, segment.start + span * Double(i) / Double(steps))
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        for i in (0...steps).reversed() {
            path.addLine(to: g.point(r0, segment.start + span * Double(i) / Double(steps)))
        }
        path.closeSubpath()
        return path
    }

    private func hub(_ g: Geometry, focus: FileNode?, hovered: FileNode?, canGoUp: Bool) -> some View {
        let shown = hovered ?? focus

        var subtitle = ""
        if let shown, let focus, shown !== focus, focus.size > 0 {
            subtitle = "\(formatPercent(Double(shown.size) / Double(focus.size))) of \(focus.name)"
        } else if canGoUp {
            subtitle = "Click to go up"
        }

        return VStack(spacing: 4) {
            Text(shown?.name ?? "")
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(shown.map { formatBytes($0.size) } ?? "")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: g.hub * 1.7)
        .position(g.center)
        .allowsHitTesting(false)
    }

    // MARK: Hit testing

    private func node(at point: CGPoint, _ g: Geometry, segments: [Segment]) -> FileNode? {
        let r = g.radius(of: point)
        guard r > g.hub, r < g.outer else { return nil }

        let dx = Double(point.x - g.center.x)
        let dy = Double(point.y - g.center.y)
        var angle = atan2(dx, -dy)   // 0 = 12 o'clock, clockwise
        if angle < 0 { angle += 2 * Double.pi }

        let depth = Int((r - g.hub) / g.ring)
        return segments.first { $0.depth == depth && angle >= $0.start && angle < $0.end }?.node
    }

    private func tap(at point: CGPoint, _ g: Geometry, segments: [Segment]) {
        if g.radius(of: point) <= g.hub {
            model.up()
        } else if let node = node(at: point, g, segments: segments) {
            model.drill(node)
        }
    }
}

// MARK: - Geometry

struct Geometry {
    let center: CGPoint
    let outer: CGFloat
    let hub: CGFloat
    let ring: CGFloat

    init(size: CGSize) {
        center = CGPoint(x: size.width / 2, y: size.height / 2)
        outer = max(40, min(size.width, size.height) / 2 - 4)
        hub = outer * 0.3
        ring = (outer - hub) / CGFloat(SunburstLayout.rings)
    }

    func point(_ radius: CGFloat, _ angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(sin(angle)),
            y: center.y - radius * CGFloat(cos(angle))
        )
    }

    func radius(of point: CGPoint) -> CGFloat {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return (dx * dx + dy * dy).squareRoot()
    }
}
