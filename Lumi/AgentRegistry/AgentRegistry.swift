//
//  AgentRegistry.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

enum AgentRegistryError: Error {
    case missingBundledResource
}

enum AgentRegistry {
    static func loadBundledDefaults(bundle: Bundle = .main) throws -> [AgentDefinition] {
        guard let url = bundle.url(forResource: "agents", withExtension: "json") else {
            throw AgentRegistryError.missingBundledResource
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([AgentDefinition].self, from: data)
    }

    static var userOverridesURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Lumi", isDirectory: true)
            .appendingPathComponent("agents.json")
    }

    static func loadUserOverrides(url: URL) -> [AgentDefinition] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([AgentDefinition].self, from: data)) ?? []
    }

    static func loadAll(
        bundle: Bundle = .main,
        userOverridesURL: URL = AgentRegistry.userOverridesURL
    ) throws -> [AgentDefinition] {
        let defaults = try loadBundledDefaults(bundle: bundle)
        let overrides = loadUserOverrides(url: userOverridesURL)
        return merge(defaults: defaults, overrides: overrides)
    }

    static func merge(defaults: [AgentDefinition], overrides: [AgentDefinition]) -> [AgentDefinition] {
        var byID = Dictionary(uniqueKeysWithValues: defaults.map { ($0.id, $0) })
        for override in overrides {
            byID[override.id] = override
        }

        let merged = defaults.map { byID[$0.id] ?? $0 }
        let defaultIDs = Set(defaults.map(\.id))
        let additions = overrides.filter { !defaultIDs.contains($0.id) }
        return merged + additions
    }
}
