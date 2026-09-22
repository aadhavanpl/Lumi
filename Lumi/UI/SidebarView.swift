//
//  SidebarView.swift
//  Lumi
//
//  Created by Aadhavan on 09/08/26.
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
                    Label(scope.displayName, systemImage: scope.systemImage)
                        .tag(SidebarSection.byScope(scope))
                }
            }

            Section("By Agent") {
                ForEach(InventoryFiltering.distinctAgentIDs(in: items), id: \.self) { agentID in
                    Label(AgentIcon.displayName(forAgentID: agentID), systemImage: "cpu")
                        .tag(SidebarSection.byAgent(agentID))
                }
            }
        }
    }

    private var selectionBinding: Binding<SidebarSection?> {
        Binding(get: { selection }, set: { newValue in if let newValue { selection = newValue } })
    }
}

#Preview {
    SidebarView(items: [], selection: .constant(.allSkills))
}
