import SwiftUI

struct HistoryView: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @State private var showingSettings = false
    @State private var itemToDelete: ClipboardItem?
    @State private var showingDeleteConfirmation = false
    @AppStorage("displayLimit") private var displayLimit: Int = 0
    
    var displayedItems: [ClipboardItem] {
        if displayLimit == 0 {
            return clipboardManager.recentItems
        } else {
            return Array(clipboardManager.recentItems.prefix(displayLimit))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipboard History")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button {
                    showingSettings.toggle()
                } label: {
                    Image(systemName: "gear")
                        .foregroundColor(showingSettings ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            List(displayedItems) { item in
                HistoryItemView(item: item)
                    .onTapGesture(count: 2) {
                        clipboardManager.copyToClipboard(item: item)
                    }
                    .contextMenu {
                        Button(action: {
                            clipboardManager.copyToClipboard(item: item)
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: {
                            itemToDelete = item
                            showingDeleteConfirmation = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            }
            .listStyle(PlainListStyle())
            
            if displayLimit > 0 && clipboardManager.recentItems.count > displayLimit {
                Text("Showing \(displayLimit) of \(clipboardManager.recentItems.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .frame(width: 400, height: 300)
                .background(VisualEffectView())
                .overlay(
                    Button(action: {
                        showingSettings = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(8),
                    alignment: .topTrailing
                )
        }
        .frame(minWidth: 360, minHeight: 400)
        .onAppear {
            clipboardManager.loadRecentItems()
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Item"),
                message: Text("Are you sure you want to delete this item?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let item = itemToDelete {
                        clipboardManager.deleteItem(item)
                        itemToDelete = nil
                    }
                },
                secondaryButton: .cancel() {
                    itemToDelete = nil
                }
            )
        }
    }
}

struct HistoryItemView: View {
    let item: ClipboardItem
    @State private var isHovering = false
    @State private var showPreview = false
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss"
        return formatter.string(from: item.timestamp)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 左侧图标和内容
            switch item.type {
            case .text:
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                if let text = item.content {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(text)
                            .lineLimit(2)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        
                        Text(formattedDate)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
            case .image:
                Image(systemName: "photo.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                if let imageData = item.imageData,
                   let nsImage = NSImage(data: imageData) {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 100)
                        
                        Text(formattedDate)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                showPreview = true
            }
        }
        .popover(isPresented: $showPreview, arrowEdge: .trailing) {
            PreviewPopover(item: item, isShowing: $showPreview)
        }
    }
}

struct PreviewPopover: View {
    let item: ClipboardItem
    @Binding var isShowing: Bool
    @State private var isHoveringPreview = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                switch item.type {
                case .text:
                    if let text = item.content {
                        Text(text)
                            .font(.system(size: 14))
                            .textSelection(.enabled)
                            .padding()
                    }
                case .image:
                    if let imageData = item.imageData,
                       let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 500, maxHeight: 500)
                            .padding()
                    }
                }
            }
        }
        .frame(maxWidth: 500, maxHeight: 500)
        .onHover { hovering in
            isHoveringPreview = hovering
            if !hovering {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if !isHoveringPreview {
                        isShowing = false
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryView()
}
