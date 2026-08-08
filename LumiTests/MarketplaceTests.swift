//
//  MarketplaceTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
import Testing
@testable import Lumi

struct MarketplaceTests {

    // Fixture entries taken verbatim from claude-plugins-official's marketplace.json,
    // the same catalog ADR 0007 cites for the superpowers pinned-sha example.
    private let fixtureJSON = """
    {
      "name": "claude-plugins-official",
      "plugins": [
        {
          "name": "agent-sdk-dev",
          "category": "development",
          "source": "./plugins/agent-sdk-dev"
        },
        {
          "name": "42crunch-api-security-testing",
          "category": "security",
          "source": {
            "source": "git-subdir",
            "url": "https://github.com/42Crunch-AI/claude-plugins.git",
            "path": "plugins/api-security-testing",
            "ref": "v1.5.5",
            "sha": "bc781f96be8ce17a2972e8a9a3ef38b1ca7e8cc4"
          }
        },
        {
          "name": "superpowers",
          "category": "development",
          "source": {
            "source": "url",
            "url": "https://github.com/obra/superpowers.git",
            "sha": "896224c4b1879920ab573417e68fd51d2ccc9072"
          }
        }
      ]
    }
    """

    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func write(_ path: String, in root: URL, contents: String = "{}") throws {
        let url = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    @Test func discoveredURLsFindsMarketplaceJSONUnderEachMarketplaceDirectory() throws {
        let configDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: configDir) }
        try write("plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json", in: configDir)
        try write("plugins/marketplaces/expo-plugins/.claude-plugin/marketplace.json", in: configDir)

        let urls = Marketplace.discoveredURLs(environment: ["CLAUDE_CONFIG_DIR": configDir.path])

        #expect(Set(urls.map(\.path)) == Set([
            configDir.appendingPathComponent("plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json").path,
            configDir.appendingPathComponent("plugins/marketplaces/expo-plugins/.claude-plugin/marketplace.json").path
        ]))
    }

    @Test func discoveredURLsSkipsMarketplaceDirectoriesMissingMarketplaceJSON() throws {
        let configDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: configDir) }
        try write("plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json", in: configDir)
        try FileManager.default.createDirectory(
            at: configDir.appendingPathComponent("plugins/marketplaces/empty-marketplace"),
            withIntermediateDirectories: true
        )

        let urls = Marketplace.discoveredURLs(environment: ["CLAUDE_CONFIG_DIR": configDir.path])

        #expect(urls.map(\.path) == [
            configDir.appendingPathComponent("plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json").path
        ])
    }

    @Test func discoveredURLsReturnsEmptyWhenMarketplacesDirectoryDoesNotExist() {
        let configDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: configDir) }

        let urls = Marketplace.discoveredURLs(environment: ["CLAUDE_CONFIG_DIR": configDir.path])

        #expect(urls.isEmpty)
    }

    @Test func decodesLocalStringSourceAsLocalCase() throws {
        let marketplace = try Marketplace.decode(from: Data(fixtureJSON.utf8))
        let plugin = try #require(marketplace.plugins.first { $0.name == "agent-sdk-dev" })

        guard case .local(let path) = plugin.source else {
            Issue.record("expected .local source, got \(plugin.source)")
            return
        }
        #expect(path == "./plugins/agent-sdk-dev")
    }

    @Test func decodesGitSubdirObjectSourceWithPathRefAndSha() throws {
        let marketplace = try Marketplace.decode(from: Data(fixtureJSON.utf8))
        let plugin = try #require(marketplace.plugins.first { $0.name == "42crunch-api-security-testing" })

        guard case .pinned(let pinned) = plugin.source else {
            Issue.record("expected .pinned source, got \(plugin.source)")
            return
        }
        #expect(pinned.kind == "git-subdir")
        #expect(pinned.url == "https://github.com/42Crunch-AI/claude-plugins.git")
        #expect(pinned.path == "plugins/api-security-testing")
        #expect(pinned.ref == "v1.5.5")
        #expect(pinned.sha == "bc781f96be8ce17a2972e8a9a3ef38b1ca7e8cc4")
    }

    @Test func decodesUrlObjectSourceWithoutPathOrRef() throws {
        let marketplace = try Marketplace.decode(from: Data(fixtureJSON.utf8))
        let plugin = try #require(marketplace.plugins.first { $0.name == "superpowers" })

        guard case .pinned(let pinned) = plugin.source else {
            Issue.record("expected .pinned source, got \(plugin.source)")
            return
        }
        #expect(pinned.kind == "url")
        #expect(pinned.path == nil)
        #expect(pinned.ref == nil)
        #expect(pinned.sha == "896224c4b1879920ab573417e68fd51d2ccc9072")
    }
}
