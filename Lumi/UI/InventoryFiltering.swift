//
//  InventoryFiltering.swift
//  Lumi
//

import Foundation

enum InventoryFiltering {
    static func filteredItems(_ items: [SkillInventoryItem], selection: SidebarSection) -> [SkillInventoryItem] {
        let matched: [SkillInventoryItem]
        switch selection {
        case .allSkills:
            matched = items
        case .byScope(let scope):
            matched = items.filter { $0.scope == scope }
        case .byAgent(let agentID):
            matched = items.filter { $0.agentID == agentID }
        case .plugins:
            matched = items.filter {
                if case .plugin = $0.origin { return true }
                return false
            }
        case .needsAttention:
            matched = items.filter { !$0.statuses.isEmpty }
        }
        return matched.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func distinctScopes(in items: [SkillInventoryItem]) -> [SkillScope] {
        var seen: [SkillScope] = []
        for item in items where !seen.contains(item.scope) {
            seen.append(item.scope)
        }
        return seen
    }

    static func distinctAgentIDs(in items: [SkillInventoryItem]) -> [String] {
        Array(Set(items.map(\.agentID))).sorted()
    }
}
