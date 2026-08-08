//
//  ClaudeSettings.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

struct ClaudeSettings: Decodable, Equatable {
    let enabledPlugins: [String: Bool]

    private enum CodingKeys: String, CodingKey {
        case enabledPlugins
    }

    init(enabledPlugins: [String: Bool] = [:]) {
        self.enabledPlugins = enabledPlugins
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabledPlugins = try container.decodeIfPresent([String: Bool].self, forKey: .enabledPlugins) ?? [:]
    }

    static func decode(from data: Data) throws -> ClaudeSettings {
        try JSONDecoder().decode(ClaudeSettings.self, from: data)
    }

    static func defaultURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        let override = environment["CLAUDE_CONFIG_DIR"].flatMap { $0.isEmpty ? nil : $0 }
        let base = override ?? (NSHomeDirectory() as NSString).appendingPathComponent(".claude")
        return URL(fileURLWithPath: base).appendingPathComponent("settings.json")
    }
}
