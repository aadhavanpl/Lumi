//
//  InventoryStore.swift
//  Lumi
//

import Foundation
import Observation

@MainActor
@Observable
final class InventoryStore {
    private(set) var items: [SkillInventoryItem] = []
    private(set) var isLoading = false
    var selection: SidebarSection = .allSkills

    func refresh(
        registry: [AgentDefinition]? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) async {
        isLoading = true
        await Task.yield()
        let resolvedRegistry = registry ?? (try? AgentRegistry.loadAll()) ?? []
        items = Self.buildInventory(registry: resolvedRegistry, environment: environment, fileManager: fileManager)
        isLoading = false
    }

    nonisolated static func buildInventory(
        registry: [AgentDefinition],
        environment: [String: String],
        fileManager: FileManager
    ) -> [SkillInventoryItem] {
        let discovered = SkillScanner.scanGlobalSkills(
            registry: registry,
            environment: environment,
            fileManager: fileManager
        )

        return SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: InventorySources.loadGlobalLockfile(environment: environment, fileManager: fileManager),
            installedPlugins: InventorySources.loadInstalledPlugins(environment: environment, fileManager: fileManager),
            settings: InventorySources.loadSettings(environment: environment, fileManager: fileManager),
            marketplaces: InventorySources.loadMarketplaces(environment: environment, fileManager: fileManager),
            fileManager: fileManager
        )
    }
}
