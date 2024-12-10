import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    private let maxItems = 100 // 最大保存数量
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("clipboard.db")
        
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            let createTableSQL = """
                CREATE TABLE IF NOT EXISTS clipboard_items (
                    id TEXT PRIMARY KEY,
                    timestamp DOUBLE,
                    type TEXT,
                    content TEXT,
                    image_data BLOB
                );
                """
            
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, createTableSQL, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Created table successfully")
                }
            }
            sqlite3_finalize(statement)
        }
    }
    
    func saveItem(_ item: ClipboardItem) {
        let insertSQL = """
            INSERT OR REPLACE INTO clipboard_items (id, timestamp, type, content, image_data)
            VALUES (?, ?, ?, ?, ?);
            """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, item.id.uuidString, -1, nil)
            sqlite3_bind_double(statement, 2, item.timestamp.timeIntervalSince1970)
            sqlite3_bind_text(statement, 3, item.type.rawValue, -1, nil)
            
            if let content = item.content {
                sqlite3_bind_text(statement, 4, content, -1, nil)
            } else {
                sqlite3_bind_null(statement, 4)
            }
            
            if let imageData = item.imageData {
                sqlite3_bind_blob(statement, 5, (imageData as NSData).bytes, Int32(imageData.count), nil)
            } else {
                sqlite3_bind_null(statement, 5)
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Saved item successfully")
            }
            
            sqlite3_finalize(statement)
        }
        
        // 清理旧数据
        cleanOldItems()
    }
    
    func getRecentItems() -> [ClipboardItem] {
        var items: [ClipboardItem] = []
        let querySQL = """
            SELECT id, timestamp, type, content, image_data
            FROM clipboard_items
            ORDER BY timestamp DESC
            LIMIT ?;
            """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(maxItems))
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let idString = String(cString: sqlite3_column_text(statement, 0))
                let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
                let typeString = String(cString: sqlite3_column_text(statement, 2))
                
                var content: String?
                if let contentText = sqlite3_column_text(statement, 3) {
                    content = String(cString: contentText)
                }
                
                var imageData: Data?
                if let blob = sqlite3_column_blob(statement, 4) {
                    let size = Int(sqlite3_column_bytes(statement, 4))
                    imageData = Data(bytes: blob, count: size)
                }
                
                if let id = UUID(uuidString: idString),
                   let type = ClipboardItem.ItemType(rawValue: typeString) {
                    let item = ClipboardItem(id: id,
                                          type: type,
                                          timestamp: timestamp,
                                          content: content,
                                          imageData: imageData)
                    items.append(item)
                }
            }
        }
        sqlite3_finalize(statement)
        return items
    }
    
    func deleteItem(_ item: ClipboardItem) {
        let deleteSQL = "DELETE FROM clipboard_items WHERE id = ?;"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, item.id.uuidString, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Deleted item successfully")
            }
        }
        sqlite3_finalize(statement)
    }
    
    func clearAllItems() {
        let deleteSQL = "DELETE FROM clipboard_items;"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Cleared all items successfully")
            }
        }
        sqlite3_finalize(statement)
    }
    
    private func cleanOldItems() {
        let deleteOldSQL = """
            DELETE FROM clipboard_items
            WHERE id NOT IN (
                SELECT id FROM clipboard_items
                ORDER BY timestamp DESC
                LIMIT ?
            );
            """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteOldSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(maxItems))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Cleaned old items successfully")
            }
        }
        sqlite3_finalize(statement)
    }
    
    // 获取数据库文件大小
    func getDatabaseFileSize() -> Int64 {
        let fileURL = try! FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("clipboard.db")
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            print("Error getting file size: \(error)")
            return 0
        }
    }
    
    // 获取数据库文件路径
    func getDatabasePath() -> String {
        let fileURL = try! FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("clipboard.db")
        return fileURL.path
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
}
