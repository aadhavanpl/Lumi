//
//  SkillInventoryBuilderTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
import Testing
@testable import Lumi

struct SkillInventoryBuilderTests {

    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func writeSkillMD(in skillDir: URL, name: String? = nil, description: String? = nil) throws {
        try FileManager.default.createDirectory(at: skillDir, withIntermediateDirectories: true)
        var frontmatter = "---\n"
        if let name { frontmatter += "name: \(name)\n" }
        if let description { frontmatter += "description: \(description)\n" }
        frontmatter += "---\n"
        try frontmatter.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
    }

    private func emptyLockfile() -> GlobalLockfile {
        GlobalLockfile(version: 3, skills: [:], dismissed: [], lastSelectedAgents: [])
    }

    private func emptyInstalledPlugins() -> InstalledPlugins {
        InstalledPlugins(version: 2, plugins: [:])
    }

    private func emptySettings() throws -> ClaudeSettings {
        try ClaudeSettings.decode(from: Data("{}".utf8))
    }

    @Test func buildsHandWrittenItemUsingFrontmatterNameAndDescription() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let skillDir = root.appendingPathComponent("grill-me")
        try writeSkillMD(in: skillDir, name: "grill-me", description: "Interview the user relentlessly.")
        let discovered = [DiscoveredSkill(path: skillDir, agentID: "claude-code", scope: .global)]

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: emptyLockfile(),
            installedPlugins: emptyInstalledPlugins(),
            settings: try emptySettings(),
            marketplaces: []
        )

        #expect(items.count == 1)
        #expect(items[0].name == "grill-me")
        #expect(items[0].description == "Interview the user relentlessly.")
        #expect(items[0].origin == .handWritten)
        #expect(items[0].statuses.isEmpty)
    }

    @Test func fallsBackToDirectoryNameWhenFrontmatterNameIsMissing() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let skillDir = root.appendingPathComponent("undocumented-skill")
        try FileManager.default.createDirectory(at: skillDir, withIntermediateDirectories: true)
        let discovered = [DiscoveredSkill(path: skillDir, agentID: "claude-code", scope: .global)]

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: emptyLockfile(),
            installedPlugins: emptyInstalledPlugins(),
            settings: try emptySettings(),
            marketplaces: []
        )

        #expect(items[0].name == "undocumented-skill")
        #expect(items[0].description == nil)
    }

    @Test func resolvesPluginOriginAndCarriesVersion() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let installPath = root.appendingPathComponent("plugins/cache/claude-plugins-official/superpowers/6.0.3")
        let skillDir = installPath.appendingPathComponent("skills/brainstorming")
        try writeSkillMD(in: skillDir, name: "brainstorming")
        let discovered = [DiscoveredSkill(path: skillDir, agentID: "claude-code", scope: .global)]
        let plugins = InstalledPlugins(version: 2, plugins: [
            "superpowers@claude-plugins-official": [InstalledPluginEntry(
                scope: "user",
                projectPath: nil,
                installPath: installPath.path,
                version: "6.0.3",
                installedAt: Date(),
                lastUpdated: Date(),
                gitCommitSha: "896224c4b1879920ab573417e68fd51d2ccc9072"
            )]
        ])

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: emptyLockfile(),
            installedPlugins: plugins,
            settings: try emptySettings(),
            marketplaces: []
        )

        #expect(items[0].origin == .plugin(name: "superpowers", marketplaceName: "claude-plugins-official", version: "6.0.3"))
    }

    @Test func flagsPluginCatalogDriftedStatusWhenInstalledShaDiffersFromPinnedSha() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let installPath = root.appendingPathComponent("plugins/cache/claude-plugins-official/superpowers/6.0.3")
        try writeSkillMD(in: installPath, name: "superpowers")
        let discovered = [DiscoveredSkill(path: installPath, agentID: "claude-code", scope: .global)]
        let plugins = InstalledPlugins(version: 2, plugins: [
            "superpowers@claude-plugins-official": [InstalledPluginEntry(
                scope: "user",
                projectPath: nil,
                installPath: installPath.path,
                version: "6.0.3",
                installedAt: Date(),
                lastUpdated: Date(),
                gitCommitSha: "6fd4507659784c351abbd2bc264c7162cfd386dc"
            )]
        ])
        let marketplace = Marketplace(name: "claude-plugins-official", plugins: [
            MarketplacePlugin(name: "superpowers", category: "development", source: .pinned(PinnedMarketplaceSource(
                kind: "url",
                url: "https://github.com/obra/superpowers.git",
                path: nil,
                ref: nil,
                sha: "896224c4b1879920ab573417e68fd51d2ccc9072"
            )))
        ])
        let settings = try ClaudeSettings.decode(from: Data("""
        { "enabledPlugins": { "superpowers@claude-plugins-official": true } }
        """.utf8))

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: emptyLockfile(),
            installedPlugins: plugins,
            settings: settings,
            marketplaces: [marketplace]
        )

        #expect(items[0].statuses == [.pluginCatalogDrifted(
            installedSha: "6fd4507659784c351abbd2bc264c7162cfd386dc",
            pinnedSha: "896224c4b1879920ab573417e68fd51d2ccc9072"
        )])
    }

    @Test func flagsInstalledButDisabledStatusWhenSettingsKeyIsMissing() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let installPath = root.appendingPathComponent("plugins/cache/claude-plugins-official/swift-lsp/1.0.0")
        try writeSkillMD(in: installPath, name: "swift-lsp")
        let discovered = [DiscoveredSkill(path: installPath, agentID: "claude-code", scope: .global)]
        let plugins = InstalledPlugins(version: 2, plugins: [
            "swift-lsp@claude-plugins-official": [InstalledPluginEntry(
                scope: "user",
                projectPath: nil,
                installPath: installPath.path,
                version: "1.0.0",
                installedAt: Date(),
                lastUpdated: Date(),
                gitCommitSha: nil
            )]
        ])

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: emptyLockfile(),
            installedPlugins: plugins,
            settings: try emptySettings(),
            marketplaces: []
        )

        #expect(items[0].statuses == [.installedButDisabled])
    }

    @Test func producesNoStatusesForRepoInstallOrigin() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let skillDir = root.appendingPathComponent("grill-me")
        try writeSkillMD(in: skillDir, name: "grill-me")
        let discovered = [DiscoveredSkill(path: skillDir, agentID: "claude-code", scope: .global)]
        let lockfile = GlobalLockfile(version: 3, skills: [
            "grill-me": GlobalLockfileEntry(
                source: "mattpocock/skills",
                sourceType: "github",
                sourceUrl: "https://github.com/mattpocock/skills.git",
                skillPath: "skills/productivity/grill-me/SKILL.md",
                skillFolderHash: "8320e7b87f7b208f50ce165b1dd43d1e93c8e801",
                pluginName: nil,
                installedAt: Date(),
                updatedAt: Date()
            )
        ], dismissed: [], lastSelectedAgents: [])

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: lockfile,
            installedPlugins: emptyInstalledPlugins(),
            settings: try emptySettings(),
            marketplaces: []
        )

        #expect(items[0].origin == .repoInstall(
            source: "mattpocock/skills",
            skillFolderHash: "8320e7b87f7b208f50ce165b1dd43d1e93c8e801"
        ))
        #expect(items[0].statuses.isEmpty)
    }

    @Test func producesNoDriftStatusWhenPluginsMarketplaceIsNotInScannedSet() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let installPath = root.appendingPathComponent("plugins/cache/claude-plugins-official/superpowers/6.0.3")
        try writeSkillMD(in: installPath, name: "superpowers")
        let discovered = [DiscoveredSkill(path: installPath, agentID: "claude-code", scope: .global)]
        let plugins = InstalledPlugins(version: 2, plugins: [
            "superpowers@claude-plugins-official": [InstalledPluginEntry(
                scope: "user",
                projectPath: nil,
                installPath: installPath.path,
                version: "6.0.3",
                installedAt: Date(),
                lastUpdated: Date(),
                gitCommitSha: "6fd4507659784c351abbd2bc264c7162cfd386dc"
            )]
        ])
        let settings = try ClaudeSettings.decode(from: Data("""
        { "enabledPlugins": { "superpowers@claude-plugins-official": true } }
        """.utf8))

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: emptyLockfile(),
            installedPlugins: plugins,
            settings: settings,
            marketplaces: []
        )

        #expect(items[0].statuses.isEmpty)
    }
}
