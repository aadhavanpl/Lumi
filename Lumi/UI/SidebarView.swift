//
//  SidebarView.swift
//  Lumi
//

import SwiftUI

struct SidebarView: View {
    let items: [SkillInventoryItem]
    @Binding var selection: SidebarSection

    var body: some View {
        List(selection: selectionBinding) {
            Label("All Skills", systemImage: "square.stack")
                .tag(SidebarSection.allSkills)

            Section("By Scope") {
                ForEach(InventoryFiltering.distinctScopes(in: items), id: \.self) { scope in
                    Label(scopeLabel(scope), systemImage: "folder")
                        .tag(SidebarSection.byScope(scope))
                }
            }

            Section("By Agent") {
                ForEach(InventoryFiltering.distinctAgentIDs(in: items), id: \.self) { agentID in
                    Label(agentID, systemImage: "cpu")
                        .tag(SidebarSection.byAgent(agentID))
                }
            }

            Label("Plugins", systemImage: "puzzlepiece.extension")
                .tag(SidebarSection.plugins)

            Label("Needs Attention", systemImage: "exclamationmark.circle")
                .badge(needsAttentionCount)
                .tag(SidebarSection.needsAttention)
        }
    }

    /// List(selection:) on macOS requires an optional binding; the store's selection always
    /// has a concrete default, so this adapts between the two without exposing Optional upward.
    private var selectionBinding: Binding<SidebarSection?> {
        Binding(get: { selection }, set: { newValue in if let newValue { selection = newValue } })
    }

    private var needsAttentionCount: Int {
        items.filter { !$0.statuses.isEmpty }.count
    }

    private func scopeLabel(_ scope: SkillScope) -> String {
        switch scope {
        case .global: return "Global"
        case .project(let root): return root.lastPathComponent
        }
    }
}

#Preview {
    SidebarView(items: [], selection: .constant(.allSkills))
}
