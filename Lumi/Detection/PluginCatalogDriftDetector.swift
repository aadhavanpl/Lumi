//
//  PluginCatalogDriftDetector.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

enum PluginCatalogDriftStatus: Equatable {
    case upToDate
    case drifted(installedSha: String, pinnedSha: String)
    case unknown
}

enum PluginCatalogDriftDetector {
    static func detect(
        pluginName: String,
        installed: InstalledPluginEntry,
        marketplace: Marketplace
    ) -> PluginCatalogDriftStatus {
        guard let installedSha = installed.gitCommitSha else { return .unknown }
        guard let plugin = marketplace.plugins.first(where: { $0.name == pluginName }) else { return .unknown }
        guard case .pinned(let pinned) = plugin.source, let pinnedSha = pinned.sha else { return .unknown }
        return installedSha == pinnedSha
            ? .upToDate
            : .drifted(installedSha: installedSha, pinnedSha: pinnedSha)
    }
}
