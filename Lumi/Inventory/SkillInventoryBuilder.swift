//
//  SkillInventoryBuilder.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

struct SkillInventoryItem: Equatable {
    let name: String
    let description: String?
    let path: URL
    let agentID: String
    let scope: SkillScope
    let origin: SkillOrigin
    let statuses: [SkillStatus]
}

enum SkillStatus: Equatable {
    case pluginCatalogDrifted(installedSha: String, pinnedSha: String)
    case installedButDisabled
}

enum SkillInventoryBuilder {
    static func build(
        discovered: [DiscoveredSkill],
        globalLockfile: GlobalLockfile,
        installedPlugins: InstalledPlugins,
        settings: ClaudeSettings,
        marketplaces: [Marketplace],
        fileManager: FileManager = .default
    ) -> [SkillInventoryItem] {
        func buildItem(for skill: DiscoveredSkill) -> SkillInventoryItem {
            let origin = SkillOriginResolver.resolve(
                path: skill.path,
                globalLockfile: globalLockfile,
                installedPlugins: installedPlugins
            )
            let frontmatter = SkillFrontmatter.parse(
                contentsOf: skill.path.appendingPathComponent("SKILL.md"),
                fileManager: fileManager
            )

            return SkillInventoryItem(
                name: frontmatter.name ?? skill.path.lastPathComponent,
                description: frontmatter.description,
                path: skill.path,
                agentID: skill.agentID,
                scope: skill.scope,
                origin: origin,
                statuses: statuses(
                    for: origin,
                    installedPlugins: installedPlugins,
                    settings: settings,
                    marketplaces: marketplaces
                )
            )
        }

        func statuses(
            for origin: SkillOrigin,
            installedPlugins: InstalledPlugins,
            settings: ClaudeSettings,
            marketplaces: [Marketplace]
        ) -> [SkillStatus] {
            guard case .plugin(let name, let marketplaceName, let version) = origin else { return [] }

            var statuses: [SkillStatus] = []
            let key = "\(name)@\(marketplaceName)"

            if let entry = installedPlugins.plugins[key]?.first(where: { $0.version == version }),
               let marketplace = marketplaces.first(where: { $0.name == marketplaceName }),
               case .drifted(let installedSha, let pinnedSha) = PluginCatalogDriftDetector.detect(
                   pluginName: name,
                   installed: entry,
                   marketplace: marketplace
               ) {
                statuses.append(.pluginCatalogDrifted(installedSha: installedSha, pinnedSha: pinnedSha))
            }

            if settings.enabledPlugins[key] != true {
                statuses.append(.installedButDisabled)
            }

            return statuses
        }

        return discovered.map(buildItem)
    }
}
