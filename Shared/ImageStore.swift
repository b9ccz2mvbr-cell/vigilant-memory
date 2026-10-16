import Foundation
import UIKit

/// 消费图片的存放。
///
/// 图片**不塞进 JSON**（那会让每次读记录都慢得要死），
/// 而是作为文件放在 App Group 容器的 `images/` 里，记录里只存文件名。
///
/// 存图是**可选的** —— 不传图完全不填这个字段。
enum ImageStore {

    /// 图片目录。App Group 没配好时退回 Documents。
    static var directory: URL? {
        let fm = FileManager.default
        let base: URL?
        if let group = fm.containerURL(forSecurityApplicationGroupIdentifier: BudgetStore.appGroupID) {
            base = group
        } else {
            base = fm.urls(for: .documentDirectory, in: .userDomainMask).first
        }
        guard let root = base else { return nil }
        let dir = root.appendingPathComponent("images", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// 保存一张图，返回文件名（失败返回 nil）。
    ///
    /// 会先**缩到长边 1600 并压成 JPEG**：收据/商品照这个尺寸足够看清，
    /// 但体积能从 4 MB 降到 200 KB 左右。
    static func save(_ image: UIImage) -> String? {
        guard let dir = directory else { return nil }
        let resized = downscale(image, maxSide: 1600)
        guard let data = resized.jpegData(compressionQuality: 0.8) else { return nil }
        let name = "img_\(UUID().uuidString).jpg"
        let url = dir.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func url(for name: String) -> URL? {
        guard let dir = directory else { return nil }
        let u = dir.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: u.path) ? u : nil
    }

    static func load(_ name: String) -> UIImage? {
        guard let u = url(for: name) else { return nil }
        return UIImage(contentsOfFile: u.path)
    }

    static func delete(_ name: String) {
        guard let u = url(for: name) else { return }
        try? FileManager.default.removeItem(at: u)
    }

    /// 清掉没有被任何记录引用的图片（删记录后调用）
    static func purgeOrphans(keeping names: Set<String>) {
        guard let dir = directory else { return }
        let files = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        for f in files where !names.contains(f) {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(f))
        }
    }

    // MARK: - 工具

    private static func downscale(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let w = image.size.width
        let h = image.size.height
        let longest = max(w, h)
        guard longest > maxSide else { return image }

        let scale = maxSide / longest
        let newSize = CGSize(width: w * scale, height: h * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
