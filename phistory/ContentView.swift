//
//  ContentView.swift
//  phistory
//
//  Created by wanghang on 2024/12/10.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager.shared
    
    var body: some View {
        List(clipboardManager.recentItems) { item in
            HistoryItemView(item: item)
                .onTapGesture(count: 2) {
                    clipboardManager.copyToClipboard(item: item)
                }
        }
        .frame(minWidth: 300, minHeight: 400)
        .onAppear {
            clipboardManager.loadRecentItems()
        }
    }
}

#Preview {
    ContentView()
}
