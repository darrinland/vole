import AppKit
import Foundation

final class FileNode: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    var size: Int64
    var children: [FileNode] = []

    init(name: String, url: URL, isDirectory: Bool, size: Int64 = 0) {
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.size = size
    }

    var isDrillable: Bool {
        isDirectory && !children.isEmpty
    }

    /// Children with a size, largest first. The chart and the list both use this order.
    var visibleChildren: [FileNode] {
        children.filter { $0.size > 0 }.sorted { $0.size > $1.size }
    }
}

// MARK: - Scanning

enum DiskScanner {
    private static let keys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isSymbolicLinkKey,
        .totalFileAllocatedSizeKey,
    ]

    private final class Counter {
        var items = 0
        var skipped = 0
    }

    /// Walks the tree on a background thread. Returns the root and the number of unreadable folders.
    static func scan(
        _ url: URL,
        progress: @escaping @Sendable (_ items: Int, _ skipped: Int) -> Void
    ) async -> (root: FileNode, skipped: Int) {
        await Task.detached(priority: .userInitiated) {
            let counter = Counter()
            let root = walk(url, counter: counter, progress: progress)
            return (root, counter.skipped)
        }.value
    }

    private static func walk(
        _ url: URL,
        counter: Counter,
        progress: @escaping @Sendable (Int, Int) -> Void
    ) -> FileNode {
        let node = FileNode(name: url.lastPathComponent, url: url, isDirectory: true)

        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: []
        ) else {
            counter.skipped += 1
            return node
        }

        for entry in entries {
            let values = try? entry.resourceValues(forKeys: keys)

            // Symlinks are skipped so the scan cannot loop or count data twice.
            if values?.isSymbolicLink == true { continue }

            if values?.isDirectory == true {
                let child = walk(entry, counter: counter, progress: progress)
                node.children.append(child)
                node.size += child.size
            } else {
                let size = Int64(values?.totalFileAllocatedSize ?? 0)
                node.children.append(FileNode(name: entry.lastPathComponent, url: entry, isDirectory: false, size: size))
                node.size += size
            }

            counter.items += 1
            if counter.items % 1000 == 0 {
                progress(counter.items, counter.skipped)
            }
        }
        return node
    }
}

// MARK: - Layout

struct Segment {
    let node: FileNode
    let depth: Int
    let start: Double   // radians, 0 = 12 o'clock, clockwise
    let end: Double
    let hue: Double     // degrees
}

enum SunburstLayout {
    static let rings = 5
    static let minSpan = 0.004   // slices narrower than this (radians) are hidden

    static func hue(forIndex index: Int) -> Double {
        (Double(index) * 137.508).truncatingRemainder(dividingBy: 360)
    }

    static func segments(for root: FileNode) -> [Segment] {
        var result: [Segment] = []

        func walk(_ node: FileNode, _ a0: Double, _ a1: Double, _ depth: Int, _ parentHue: Double) {
            guard depth < rings, node.size > 0 else { return }
            var a = a0
            for (index, child) in node.visibleChildren.enumerated() {
                let span = (a1 - a0) * Double(child.size) / Double(node.size)
                if span < minSpan { break }
                let h = depth == 0 ? hue(forIndex: index) : parentHue
                result.append(Segment(node: child, depth: depth, start: a, end: a + span, hue: h))
                walk(child, a, a + span, depth + 1, h)
                a += span
            }
        }

        walk(root, 0, 2 * Double.pi, 0, 0)
        return result
    }
}

// MARK: - Model

@MainActor
final class DiskModel: ObservableObject {
    @Published private(set) var trail: [FileNode] = []
    @Published private(set) var segments: [Segment] = []
    @Published var hovered: FileNode?
    @Published private(set) var skipped = 0
    @Published private(set) var status = "Choose a folder to scan."
    @Published private(set) var isScanning = false

    var root: FileNode? { trail.first }
    var focus: FileNode? { trail.last }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Scan"
        if panel.runModal() == .OK, let url = panel.url {
            scan(url)
        }
    }

    func scan(_ url: URL) {
        guard !isScanning else { return }
        isScanning = true
        hovered = nil
        status = "Scanning…"

        Task {
            let result = await DiskScanner.scan(url) { items, _ in
                Task { @MainActor in
                    self.status = "Scanning… \(items.formatted()) items"
                }
            }
            skipped = result.skipped
            trail = [result.root]
            refresh()
            isScanning = false
            status = "\(formatBytes(result.root.size)) · \(url.path)"
        }
    }

    func drill(_ node: FileNode) {
        guard node.isDrillable else { return }
        trail.append(node)
        hovered = nil
        refresh()
    }

    func up() {
        guard trail.count > 1 else { return }
        trail.removeLast()
        hovered = nil
        refresh()
    }

    func jump(to index: Int) {
        trail = Array(trail.prefix(index + 1))
        hovered = nil
        refresh()
    }

    func reveal(_ node: FileNode) {
        NSWorkspace.shared.activateFileViewerSelecting([node.url])
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else { return }
        NSWorkspace.shared.open(url)
    }

    private func refresh() {
        segments = focus.map { SunburstLayout.segments(for: $0) } ?? []
    }
}

// MARK: - Formatting

func formatBytes(_ bytes: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
}

func formatPercent(_ fraction: Double) -> String {
    fraction < 0.1
        ? String(format: "%.1f%%", fraction * 100)
        : String(format: "%.0f%%", fraction * 100)
}
