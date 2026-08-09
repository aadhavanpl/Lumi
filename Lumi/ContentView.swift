//
//  ContentView.swift
//  Lumi
//

import SwiftUI

struct ContentView: View {
    @State private var store = InventoryStore()
    // Tags the list's grouped rows with their primary SkillInventoryItem's id (see
    // SkillListView), so this still resolves to a single item for the detail pane.
    @State private var selectedItemID: String?

    var body: some View {
        NavigationSplitView {
            SidebarView(items: store.items, selection: $store.selection)
        } content: {
            SkillListView(
                items: InventoryFiltering.filteredItems(store.items, selection: store.selection),
                selection: $selectedItemID
            )
        } detail: {
            SkillDetailView(item: store.items.first { $0.id == selectedItemID })
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
