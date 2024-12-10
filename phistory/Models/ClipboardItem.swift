import Foundation
import AppKit

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let type: ItemType
    let content: String?
    let imageData: Data?
    
    init(id: UUID = UUID(), type: ItemType, timestamp: Date = Date(), content: String? = nil, imageData: Data? = nil) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.content = content
        self.imageData = imageData
    }
    
    init(text: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = .text
        self.content = text
        self.imageData = nil
    }
    
    init(imageData: Data) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = .image
        self.content = nil
        
        // 压缩图片数据
        if let image = NSImage(data: imageData),
           let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData) {
            self.imageData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
        } else {
            self.imageData = imageData
        }
    }
    
    // 计算属性,用于获取压缩后的大小
    var sizeInKB: Double {
        let size = (content?.data(using: .utf8)?.count ?? 0) + (imageData?.count ?? 0)
        return Double(size) / 1024.0
    }
    
    enum ItemType: String, Codable {
        case text
        case image
        
        var stringValue: String? {
            switch self {
            case .text: return "text"
            case .image: return "image"
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, type, content, imageData
    }
}
