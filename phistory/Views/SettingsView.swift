import SwiftUI

struct SettingsView: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage("displayLimit") private var displayLimit: Int = 0  // 0 表示显示全部
    
    let displayLimitOptions = [
        (label: "All", value: 0),
        (label: "10", value: 10),
        (label: "20", value: 20),
        (label: "50", value: 50),
        (label: "100", value: 100)
    ]
    
    var databaseFileSize: String {
        let size = DatabaseManager.shared.getDatabaseFileSize()
        if size < 1024 {
            return "\(size) bytes"
        } else if size < 1024 * 1024 {
            return String(format: "%.1f KB", Double(size) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(size) / (1024.0 * 1024.0))
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox("Display Settings") {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Display Limit")
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $displayLimit) {
                                ForEach(displayLimitOptions, id: \.value) { option in
                                    Text(option.label).tag(option.value)
                                }
                            }
                            .frame(width: 100)
                        }
                        
                        Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
                    }
                    .padding(.vertical, 4)
                }
                
                GroupBox("Statistics") {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(title: "Total Records", value: "\(clipboardManager.recentItems.count)")
                        InfoRow(title: "Database Size", value: databaseFileSize)
                        InfoRow(title: "Database Location", value: DatabaseManager.shared.getDatabasePath())
                    }
                    .padding(.vertical, 4)
                }
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear All Records")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding()
        }
        .frame(width: 400, height: 300)
        .alert("Clear All Records", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clipboardManager.clearAllItems()
            }
        } message: {
            Text("Are you sure you want to delete all clipboard history records? This action cannot be undone.")
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Text(value)
                .textSelection(.enabled)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(.body, design: .monospaced))
        }
    }
}

#Preview {
    SettingsView()
}
