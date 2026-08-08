//
//  ContentView.swift
//  Lumi
//

import SwiftUI

struct ContentView: View {
    @State private var store = InventoryStore()
    @State private var selectedItem: SkillInventoryItem?

    var body: some View {
        NavigationSplitView {
            SidebarView(items: store.items, selection: $store.selection)
        } content: {
            SkillListView(
                items: InventoryFiltering.filteredItems(store.items, selection: store.selection),
                selection: $selectedItem
            )
        } detail: {
            SkillDetailView(item: selectedItem)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .task {
            await store.refresh()
        }
        .overlay {
            if store.isLoading && store.items.isEmpty {
                ProgressView("Scanning skills…")
            }
        }
    }
}

#Preview {
    ContentView()
}
