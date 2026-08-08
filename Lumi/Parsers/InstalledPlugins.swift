//
//  InstalledPlugins.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

struct InstalledPlugins: Decodable, Equatable {
    let version: Int
    let plugins: [String: [InstalledPluginEntry]]

    static func decode(from data: Data) throws -> InstalledPlugins {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .lumiISO8601
        return try decoder.decode(InstalledPlugins.self, from: data)
    }

    static func defaultURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        let override = environment["CLAUDE_CONFIG_DIR"].flatMap { $0.isEmpty ? nil : $0 }
        let base = override ?? (NSHomeDirectory() as NSString).appendingPathComponent(".claude")
        return URL(fileURLWithPath: base)
            .appendingPathComponent("plugins")
            .appendingPathComponent("installed_plugins.json")
    }
}

struct InstalledPluginEntry: Decodable, Equatable {
    let scope: String
    let projectPath: String?
    let installPath: String
    let version: String
    let installedAt: Date
    let lastUpdated: Date
    let gitCommitSha: String?
}
