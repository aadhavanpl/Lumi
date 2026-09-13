//
//  ContentView.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import SwiftUI

struct ContentView: View {
    @State private var store = InventoryStore()
    // Tags the list's grouped rows with their primary SkillInventoryItem's id (see
    // SkillListView), so this still resolves to a single item for the detail pane.
    @State private var selectedItemID: String?
    @State private var inspectorVisible = true

    var body: some View {
        NavigationSplitView {
            SidebarView(items: store.items, selection: $store.selection)
        } detail: {
            SkillListView(
                items: InventoryFiltering.filteredItems(store.items, selection: store.selection),
                selection: $selectedItemID
            )
            .navigationSplitViewColumnWidth(min: 420, ideal: 720, max: .infinity)
            .inspector(isPresented: $inspectorVisible) {
                SkillDetailView(item: store.items.first { $0.id == selectedItemID })
                    .inspectorColumnWidth(min: 280, ideal: 340, max: 480)
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            ToolbarItem {
                Button {
                    inspectorVisible.toggle()
                } label: {
                    Label("Inspector", systemImage: "sidebar.trailing")
                }
                .help("Toggle detail inspector")
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
