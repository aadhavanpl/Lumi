//
//  InventoryFilteringTests.swift
//  LumiTests
//

import Foundation
import Testing
@testable import Lumi

struct InventoryFilteringTests {

    private func item(
        name: String,
        agentID: String = "claude-code",
        scope: SkillScope = .global,
        origin: SkillOrigin = .handWritten,
        statuses: [SkillStatus] = []
    ) -> SkillInventoryItem {
        SkillInventoryItem(
            name: name,
            description: nil,
            path: URL(fileURLWithPath: "/tmp/\(name)"),
            agentID: agentID,
            scope: scope,
            origin: origin,
            statuses: statuses
        )
    }

    @Test func allSkillsReturnsEverythingSortedByNameCaseInsensitively() {
        let items = [item(name: "zebra"), item(name: "apple"), item(name: "Banana")]

        let result = InventoryFiltering.filteredItems(items, selection: .allSkills)

        #expect(result.map(\.name) == ["apple", "Banana", "zebra"])
    }

    @Test func byScopeKeepsOnlyMatchingScope() {
        let projectRoot = URL(fileURLWithPath: "/tmp/my-project")
        let items = [
            item(name: "global-skill", scope: .global),
            item(name: "project-skill", scope: .project(root: projectRoot))
        ]

        let result = InventoryFiltering.filteredItems(items, selection: .byScope(.global))

        #expect(result.map(\.name) == ["global-skill"])
    }

    @Test func byAgentKeepsOnlyMatchingAgentID() {
        let items = [
            item(name: "for-claude", agentID: "claude-code"),
            item(name: "for-codex", agentID: "codex")
        ]

        let result = InventoryFiltering.filteredItems(items, selection: .byAgent("codex"))

        #expect(result.map(\.name) == ["for-codex"])
    }

    @Test func pluginsKeepsOnlyPluginOrigin() {
        let items = [
            item(name: "a-plugin", origin: .plugin(name: "x", marketplaceName: "y", version: "1.0.0")),
            item(name: "hand-written", origin: .handWritten),
            item(name: "repo-install", origin: .repoInstall(source: "s", skillFolderHash: "h"))
        ]

        let result = InventoryFiltering.filteredItems(items, selection: .plugins)

        #expect(result.map(\.name) == ["a-plugin"])
    }

    @Test func needsAttentionKeepsOnlyItemsWithNonEmptyStatuses() {
        let items = [
            item(name: "healthy", statuses: []),
            item(name: "flagged", statuses: [.installedButDisabled])
        ]

        let result = InventoryFiltering.filteredItems(items, selection: .needsAttention)

        #expect(result.map(\.name) == ["flagged"])
    }

    @Test func distinctScopesDedupesPreservingFirstSeenOrder() {
        let projectRoot = URL(fileURLWithPath: "/tmp/my-project")
        let items = [
            item(name: "a", scope: .global),
            item(name: "b", scope: .project(root: projectRoot)),
            item(name: "c", scope: .global)
        ]

        #expect(InventoryFiltering.distinctScopes(in: items) == [.global, .project(root: projectRoot)])
    }

    @Test func distinctAgentIDsDedupesAndSortsAlphabetically() {
        let items = [
            item(name: "a", agentID: "codex"),
            item(name: "b", agentID: "claude-code"),
            item(name: "c", agentID: "codex")
        ]

        #expect(InventoryFiltering.distinctAgentIDs(in: items) == ["claude-code", "codex"])
    }

    @Test func needsAttentionCountMatchesFilteredItemsCount() {
        let items = [
            item(name: "healthy", statuses: []),
            item(name: "flagged-1", statuses: [.installedButDisabled]),
            item(name: "flagged-2", statuses: [.installedButDisabled])
        ]

        let filteredCount = InventoryFiltering.filteredItems(items, selection: .needsAttention).count

        #expect(filteredCount == 2)
    }
}
