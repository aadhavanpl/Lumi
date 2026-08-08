//
//  Marketplace.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

struct Marketplace: Decodable, Equatable {
    let name: String
    let plugins: [MarketplacePlugin]

    static func decode(from data: Data) throws -> Marketplace {
        try JSONDecoder().decode(Marketplace.self, from: data)
    }
}

struct MarketplacePlugin: Decodable, Equatable {
    let name: String
    let category: String?
    let source: MarketplacePluginSource
}

/// A plugin's `source` is either a plain relative path (part of the marketplace's own repo,
/// versioned by the marketplace's own commit) or an object pinning an external git ref/sha.
struct PinnedMarketplaceSource: Decodable, Equatable {
    let kind: String
    let url: String
    let path: String?
    let ref: String?
    let sha: String?

    private enum CodingKeys: String, CodingKey {
        case kind = "source"
        case url, path, ref, sha
    }
}

enum MarketplacePluginSource: Decodable, Equatable {
    case local(path: String)
    case pinned(PinnedMarketplaceSource)

    init(from decoder: Decoder) throws {
        if let path = try? decoder.singleValueContainer().decode(String.self) {
            self = .local(path: path)
        } else {
            self = .pinned(try PinnedMarketplaceSource(from: decoder))
        }
    }
}

extension Marketplace {
    static func discoveredURLs(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> [URL] {
        let override = environment["CLAUDE_CONFIG_DIR"].flatMap { $0.isEmpty ? nil : $0 }
        let base = override ?? (NSHomeDirectory() as NSString).appendingPathComponent(".claude")
        let marketplacesDir = URL(fileURLWithPath: base)
            .appendingPathComponent("plugins")
            .appendingPathComponent("marketplaces")
            .resolvingSymlinksInPath() // Handles symlinked CLAUDE_CONFIG_DIR; doesn't affect /var canonicalization.

        guard let entries = try? fileManager.contentsOfDirectory(
            at: marketplacesDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else {
            return []
        }

        return entries
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
            .map { $0.appendingPathComponent(".claude-plugin").appendingPathComponent("marketplace.json") }
            .filter { fileManager.fileExists(atPath: $0.path) }
    }
}
