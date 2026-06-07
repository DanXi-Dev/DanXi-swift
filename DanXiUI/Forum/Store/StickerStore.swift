import Utils
import SwiftUI
import Disk

/// A store for the remote-controlled sticker images.
///
/// **Threading contract.** The sticker collections are read from several threads — SwiftUI view bodies
/// on the main thread, and the off-main markdown pipeline (`BrowseModel.loadMoreHoles` →
/// `HolePresentation` → `inlineAttributed`) — so they must not be mutated concurrently. The previous
/// version mutated `stickerImage` incrementally inside a loop while these reads happened, corrupting the
/// dictionary storage and crashing in `_swift_release_dealloc`.
///
/// This version removes the shared-mutation hazard with structured concurrency instead of locking:
///   * `initialize()` is single-flight: concurrent callers join the same `loadTask` rather than starting
///     a second loader, so the collections only ever have one writer.
///   * Images are loaded concurrently into a *local* dictionary with a task group, then the collections
///     are published in a single assignment each — there is no incremental shared mutation to race.
///   * Publication happens-before any reader: `ForumHomePage.loadAll()` awaits `initialize()` before the
///     forum content that reads the stickers is shown, and the collections are never mutated afterwards.
final class StickerStore: ObservableObject {
    static let shared = StickerStore()

    private(set) var stickers: [Sticker] = []
    private(set) var stickerSet: Set<String> = []
    private(set) var stickerImage: [String: LoadedImage] = [:]

    /// Guards against re-entrant / concurrent loads. Main-actor isolated so the check-and-set is atomic.
    @MainActor private var loadTask: Task<Void, Error>?

    @MainActor
    func initialize() async throws {
        // Join an in-flight or already-finished load instead of starting another one.
        if let loadTask {
            return try await loadTask.value
        }

        let task = Task { try await Self.loadAllStickers() }
        loadTask = task
        do {
            try await task.value
        } catch {
            // The load failed before publishing anything; drop the task so a later visit can retry.
            loadTask = nil
            throw error
        }
    }

    /// Loads every sticker image concurrently, then publishes the collections in one shot on the main actor.
    @MainActor
    private static func loadAllStickers() async throws {
        if ConfigurationCenter.configuration.stickers.isEmpty {
            try await ConfigurationCenter.refresh()
        }

        let stickers = ConfigurationCenter.configuration.stickers

        // Decode/scale every image concurrently off the main actor (`retrieveImage` is nonisolated and
        // runs in the child tasks). A network failure for one sticker is non-fatal and just skips it.
        let stickerImage = try await withThrowingTaskGroup(of: (String, LoadedImage)?.self) { group in
            for sticker in stickers {
                group.addTask {
                    do {
                        return (sticker.id, try await retrieveImage(sticker: sticker, scale: 0.4))
                    } catch is URLError {
                        return nil // ignore network error, sticker loading failed should not be fatal
                    }
                }
            }

            var images: [String: LoadedImage] = [:]
            for try await result in group {
                if let result {
                    images[result.0] = result.1
                }
            }
            return images
        }

        // Single publication — no incremental mutation, so there is nothing for readers to race against.
        let store = StickerStore.shared
        store.stickers = stickers
        store.stickerSet = Set(stickers.map(\.id))
        store.stickerImage = stickerImage

        Task.detached {
            try? clearUnusedFiles(activeHashes: Set(stickers.map(\.sha256)))
        }
    }

    private static func retrieveImage(sticker: Sticker, scale: CGFloat = 1.0) async throws -> LoadedImage {
        let pathExtension = sticker.url.pathExtension.isEmpty ? "webp" : sticker.url.pathExtension.lowercased()
        let filename = "stickers/\(sticker.sha256).\(pathExtension)"

        let fileURL = try Disk.url(for: filename, in: .caches)

        // retrieved from disk
        if let uiImage = try? Disk.retrieve(filename, from: .caches, as: UIImage.self) {
            let scaledUIImage = scaleImage(uiImage, by: scale)
            let image = Image(uiImage: scaledUIImage)
            return LoadedImage(image: image, uiImage: scaledUIImage, fileURL: fileURL)
        }

        // download image from internet
        let (data, _) = try await URLSession.defaultSession.data(from: sticker.url)
        guard let uiImage = UIImage(data: data) else {
            throw LocatableError()
        }
        try Disk.save(data, to: .caches, as: filename)

        let scaledUIImage = scaleImage(uiImage, by: scale)
        let image = Image(uiImage: scaledUIImage)

        return LoadedImage(image: image, uiImage: scaledUIImage, fileURL: fileURL)
    }

    private static func scaleImage(_ image: UIImage, by scale: CGFloat) -> UIImage {
        guard scale > 0, scale != 1 else { return image }
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static func clearUnusedFiles(activeHashes: Set<String>) throws {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        guard var path = paths.first else { return }
        path.append(path: "stickers")

        let items = try fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
        for item in items {
            // Remove legacy transcoded caches because stickers are now stored as original WEBP data.
            if ["jpg", "jpeg"].contains(item.pathExtension.lowercased()) {
                try? fileManager.removeItem(at: item)
                continue
            }

            let filename = item.deletingPathExtension().lastPathComponent
            if !activeHashes.contains(filename) {
                try? fileManager.removeItem(at: item)
            }
        }
    }
}

struct LoadedImage {
    let image: Image
    let uiImage: UIImage
    let fileURL: URL
}
