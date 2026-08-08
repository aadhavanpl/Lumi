//
//  InventorySourcesTests.swift
//  LumiTests
//

import Foundation
import Testing
@testable import Lumi

struct InventorySourcesTests {

    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func write(_ path: String, in root: URL, contents: String) throws {
        let url = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    @Test func loadGlobalLockfileDecodesFileWhenPresent() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("skills/.skill-lock.json", in: root, contents: """
        { "version": 3, "skills": {}, "dismissed": [], "lastSelectedAgents": [] }
        """)

        let lockfile = InventorySources.loadGlobalLockfile(
            environment: ["XDG_STATE_HOME": root.path],
            fileManager: .default
        )

        #expect(lockfile.version == 3)
    }

    @Test func loadGlobalLockfileFallsBackToEmptyWhenMissing() {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let lockfile = InventorySources.loadGlobalLockfile(
            environment: ["XDG_STATE_HOME": root.path],
            fileManager: .default
        )

        #expect(lockfile.skills.isEmpty)
        #expect(lockfile.dismissed.isEmpty)
    }

    @Test func loadInstalledPluginsDecodesFileWhenPresent() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("plugins/installed_plugins.json", in: root, contents: """
        { "version": 2, "plugins": {} }
        """)

        let plugins = InventorySources.loadInstalledPlugins(
            environment: ["CLAUDE_CONFIG_DIR": root.path],
            fileManager: .default
        )

        #expect(plugins.version == 2)
    }

    @Test func loadInstalledPluginsFallsBackToEmptyWhenMissing() {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let plugins = InventorySources.loadInstalledPlugins(
            environment: ["CLAUDE_CONFIG_DIR": root.path],
            fileManager: .default
        )

        #expect(plugins.plugins.isEmpty)
    }

    @Test func loadSettingsDecodesFileWhenPresent() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("settings.json", in: root, contents: """
        { "enabledPlugins": { "a@b": true } }
        """)

        let settings = InventorySources.loadSettings(
            environment: ["CLAUDE_CONFIG_DIR": root.path],
            fileManager: .default
        )

        #expect(settings.enabledPlugins == ["a@b": true])
    }

    @Test func loadSettingsFallsBackToEmptyWhenMissing() {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let settings = InventorySources.loadSettings(
            environment: ["CLAUDE_CONFIG_DIR": root.path],
            fileManager: .default
        )

        #expect(settings.enabledPlugins.isEmpty)
    }

    @Test func loadMarketplacesDecodesEachDiscoveredFile() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("plugins/marketplaces/my-market/.claude-plugin/marketplace.json", in: root, contents: """
        { "name": "my-market", "plugins": [] }
        """)

        let marketplaces = InventorySources.loadMarketplaces(
            environment: ["CLAUDE_CONFIG_DIR": root.path],
            fileManager: .default
        )

        #expect(marketplaces.map(\.name) == ["my-market"])
    }

    @Test func loadMarketplacesSkipsFilesThatFailToDecode() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("plugins/marketplaces/broken/.claude-plugin/marketplace.json", in: root, contents: "not json")

        let marketplaces = InventorySources.loadMarketplaces(
            environment: ["CLAUDE_CONFIG_DIR": root.path],
            fileManager: .default
        )

        #expect(marketplaces.isEmpty)
    }
}
