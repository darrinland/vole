import SwiftUI

@main
struct VoleApp: App {
    @StateObject private var model = DiskModel()

    var body: some Scene {
        WindowGroup("Vole") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 820, minHeight: 560)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var model: DiskModel

    var body: some View {
        VStack(spacing: 0) {
            if model.focus != nil {
                breadcrumbs
                Divider()
                if model.skipped > 0 {
                    skippedBanner
                    Divider()
                }
                HSplitView {
                    SunburstView()
                        .frame(minWidth: 380, maxWidth: .infinity, maxHeight: .infinity)
                    FileListView()
                        .frame(minWidth: 280, idealWidth: 340)
                }
            } else {
                emptyState
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button("Choose Folder…", systemImage: "folder") {
                    model.chooseFolder()
                }
                .disabled(model.isScanning)

                Button("Scan Home", systemImage: "house") {
                    model.scan(FileManager.default.homeDirectoryForCurrentUser)
                }
                .disabled(model.isScanning)
            }
        }
        .navigationSubtitle(model.status)
    }

    private var breadcrumbs: some View {
        HStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(model.trail.enumerated()), id: \.element.id) { index, node in
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Button(node.name) {
                            model.jump(to: index)
                        }
                        .buttonStyle(.plain)
                        .lineLimit(1)
                        .foregroundStyle(index == model.trail.count - 1 ? Color.primary : Color.secondary)
                    }
                }
            }

            Spacer(minLength: 12)

            Text(formatBytes(model.root?.size ?? 0))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var skippedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
            Text("\(model.skipped) folders could not be read. Grant Full Disk Access for a complete scan.")
                .lineLimit(2)
            Spacer()
            Button("Open Privacy Settings") {
                model.openPrivacySettings()
            }
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.yellow.opacity(0.12))
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "internaldrive")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text(model.isScanning ? model.status : "See what takes up space")
                .font(.title2.weight(.semibold))

            Text("Pick a folder to scan. Nothing leaves this Mac.")
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Choose Folder…") {
                    model.chooseFolder()
                }
                .buttonStyle(.borderedProminent)

                Button("Scan Home") {
                    model.scan(FileManager.default.homeDirectoryForCurrentUser)
                }
                .buttonStyle(.bordered)
            }
            .disabled(model.isScanning)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
