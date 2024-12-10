import Cocoa

class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    @Published var recentItems: [ClipboardItem] = []
    
    private init() {
        lastChangeCount = pasteboard.changeCount
        loadRecentItems()
        startMonitoring()
    }
    
    func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    private func checkForChanges() {
        let currentCount = pasteboard.changeCount
        guard currentCount > lastChangeCount else { return }
        lastChangeCount = currentCount
        
        // 只处理文本和图片
        if let text = pasteboard.string(forType: .string) {
            addItem(text: text)
        } else if let image = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            addItem(imageData: image)
        }
    }
    
    func addItem(text: String) {
        // 检查是否已存在相同内容
        if let existingIndex = recentItems.firstIndex(where: { $0.content == text }) {
            // 如果存在，更新时间戳并移动到顶部
            recentItems.remove(at: existingIndex)
        }
        
        // 添加新项目到顶部
        let newItem = ClipboardItem(text: text)
        recentItems.insert(newItem, at: 0)
        saveRecentItems()
    }
    
    func addItem(imageData: Data) {
        // 检查是否已存在相同内容
        if let existingIndex = recentItems.firstIndex(where: { $0.imageData == imageData }) {
            // 如果存在，更新时间戳并移动到顶部
            recentItems.remove(at: existingIndex)
        }
        
        // 添加新项目到顶部
        let newItem = ClipboardItem(imageData: imageData)
        recentItems.insert(newItem, at: 0)
        saveRecentItems()
    }
    
    func copyToClipboard(item: ClipboardItem) {
        pasteboard.clearContents()
        switch item.type {
        case .text:
            if let text = item.content {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let imageData = item.imageData {
                pasteboard.setData(imageData, forType: .tiff)
            }
        }
        
        // 更新时间戳
        if let index = recentItems.firstIndex(where: { $0.id == item.id }) {
            recentItems.remove(at: index)
            recentItems.insert(item, at: 0)
            saveRecentItems()
        }
    }
    
    func deleteItem(_ item: ClipboardItem) {
        if let index = recentItems.firstIndex(where: { $0.id == item.id }) {
            recentItems.remove(at: index)
            saveRecentItems()
        }
    }
    
    func clearAllItems() {
        recentItems.removeAll()
        saveRecentItems()
    }
    
    func loadRecentItems() {
        if let data = UserDefaults.standard.data(forKey: "recentItems"),
           let items = try? JSONDecoder().decode([ClipboardItem].self, from: data) {
            recentItems = items
        }
    }
    
    private func saveRecentItems() {
        if let data = try? JSONEncoder().encode(recentItems) {
            UserDefaults.standard.set(data, forKey: "recentItems")
        }
    }
}
