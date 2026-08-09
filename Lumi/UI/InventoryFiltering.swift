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

    /// Collapses per-agent occurrences of the same skill (same name, same scope) into one row,
    /// so a skill installed for several agents renders as a single row with multiple agent chips.
    static func groupedRows(from items: [SkillInventoryItem]) -> [GroupedSkillRow] {
        var order: [GroupKey] = []
        var byKey: [GroupKey: [SkillInventoryItem]] = [:]

        for item in items {
            let key = GroupKey(name: item.name, scope: item.scope)
            if byKey[key] == nil {
                order.append(key)
            }
            byKey[key, default: []].append(item)
        }

        return order.compactMap { key in
            guard let groupedItems = byKey[key] else { return nil }
            let sorted = groupedItems.sorted {
                $0.agentID.localizedCaseInsensitiveCompare($1.agentID) == .orderedAscending
            }
            return GroupedSkillRow(items: sorted)
        }
    }

    private struct GroupKey: Hashable {
        let name: String
        let scope: SkillScope
    }
}

/// A single list row: one or more `SkillInventoryItem`s that share a name and scope, one per agent.
struct GroupedSkillRow: Identifiable, Hashable {
    let items: [SkillInventoryItem]

    var id: String { items.map(\.id).joined(separator: "|") }
    var primaryItem: SkillInventoryItem { items[0] }
    var name: String { primaryItem.name }
    var description: String? { primaryItem.description }
    var origin: SkillOrigin { primaryItem.origin }
    var scope: SkillScope { primaryItem.scope }
    var agentIDs: [String] { items.map(\.agentID) }
    var statuses: [SkillStatus] { items.flatMap(\.statuses) }
}
