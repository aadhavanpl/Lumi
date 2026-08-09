//
//  InventorySources.swift
//  Lumi
//
//  Created by Aadhavan on 09/08/26.
//

import Foundation

enum InventorySources {
    static func loadGlobalLockfile(environment: [String: String], fileManager: FileManager) -> GlobalLockfile {
        let url = GlobalLockfile.defaultURL(environment: environment)
        guard let data = fileManager.contents(atPath: url.path),
              let lockfile = try? GlobalLockfile.decode(from: data) else {
            return GlobalLockfile(version: 3, skills: [:], dismissed: [], lastSelectedAgents: [])
        }
        return lockfile
    }

    static func loadInstalledPlugins(environment: [String: String], fileManager: FileManager) -> InstalledPlugins {
        let url = InstalledPlugins.defaultURL(environment: environment)
        guard let data = fileManager.contents(atPath: url.path),
              let plugins = try? InstalledPlugins.decode(from: data) else {
            return InstalledPlugins(version: 2, plugins: [:])
        }
        return plugins
    }

    static func loadSettings(environment: [String: String], fileManager: FileManager) -> ClaudeSettings {
        let url = ClaudeSettings.defaultURL(environment: environment)
        guard let data = fileManager.contents(atPath: url.path),
              let settings = try? ClaudeSettings.decode(from: data) else {
            return ClaudeSettings()
        }
        return settings
    }

    static func loadMarketplaces(environment: [String: String], fileManager: FileManager) -> [Marketplace] {
        Marketplace.discoveredURLs(environment: environment, fileManager: fileManager).compactMap { url in
            guard let data = fileManager.contents(atPath: url.path) else { return nil }
            return try? Marketplace.decode(from: data)
        }
    }
}
