import SwiftUI

struct FileListView: View {
    @EnvironmentObject private var model: DiskModel

    var body: some View {
        let focus = model.focus
        let kids = focus?.visibleChildren ?? []
        let total = focus?.size ?? 0
        let hovered = model.hovered

        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(kids.enumerated()), id: \.element.id) { index, child in
                    FileRow(
                        node: child,
                        color: color(forIndex: index),
                        share: total > 0 ? Double(child.size) / Double(total) : 0,
                        isHot: child === hovered
                    )
                    .contentShape(Rectangle())
                    .onHover { inside in
                        model.hovered = inside ? child : nil
                    }
                    .onTapGesture {
                        model.drill(child)
                    }
                    .contextMenu {
                        Button("Reveal in Finder") { model.reveal(child) }
                    }
                }

                if kids.isEmpty, focus != nil {
                    Text("Nothing to show here.")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        }
        .background(.background.secondary)
    }

    private func color(forIndex index: Int) -> Color {
        Color(hue: SunburstLayout.hue(forIndex: index) / 360, saturation: 0.6, brightness: 0.92)
    }
}

struct FileRow: View {
    let node: FileNode
    let color: Color
    let share: Double
    let isHot: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: 10, height: 10)

                Text(node.name)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if node.isDrillable {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(formatBytes(node.size))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Text(formatPercent(share))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule()
                        .fill(color)
                        .frame(width: max(2, geo.size.width * share))
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isHot ? Color.primary.opacity(0.07) : Color.clear)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}
