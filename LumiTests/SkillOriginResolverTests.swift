//
//  SkillOriginResolverTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
import Testing
@testable import Lumi

struct SkillOriginResolverTests {

    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func installedPlugins(_ entries: [String: [InstalledPluginEntry]]) -> InstalledPlugins {
        InstalledPlugins(version: 2, plugins: entries)
    }

    private func pluginEntry(installPath: String, version: String = "1.0.0") -> InstalledPluginEntry {
        InstalledPluginEntry(
            scope: "user",
            projectPath: nil,
            installPath: installPath,
            version: version,
            installedAt: Date(),
            lastUpdated: Date(),
            gitCommitSha: nil
        )
    }

    private func lockfile(_ skills: [String: GlobalLockfileEntry]) -> GlobalLockfile {
        GlobalLockfile(version: 3, skills: skills, dismissed: [], lastSelectedAgents: [])
    }

    private func lockfileEntry(
        source: String = "mattpocock/skills",
        skillFolderHash: String = "8320e7b87f7b208f50ce165b1dd43d1e93c8e801"
    ) -> GlobalLockfileEntry {
        GlobalLockfileEntry(
            source: source,
            sourceType: "github",
            sourceUrl: "https://github.com/mattpocock/skills.git",
            skillPath: "skills/productivity/grill-me/SKILL.md",
            skillFolderHash: skillFolderHash,
            pluginName: nil,
            installedAt: Date(),
            updatedAt: Date()
        )
    }

    @Test func resolvesPluginOriginWhenPathIsContainedUnderInstallPath() {
        let installPath = "/Users/aadhavan/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.3"
        let skillPath = URL(fileURLWithPath: "\(installPath)/skills/brainstorming")
        let plugins = installedPlugins([
            "superpowers@claude-plugins-official": [pluginEntry(installPath: installPath, version: "6.0.3")]
        ])

        let origin = SkillOriginResolver.resolve(path: skillPath, globalLockfile: lockfile([:]), installedPlugins: plugins)

        #expect(origin == .plugin(name: "superpowers", marketplaceName: "claude-plugins-official", version: "6.0.3"))
    }

    @Test func resolvesRepoInstallOriginWhenDirectoryNameMatchesLockfileKey() {
        let skillPath = URL(fileURLWithPath: "/Users/aadhavan/.agents/skills/grill-me")
        let skills = lockfile(["grill-me": lockfileEntry()])

        let origin = SkillOriginResolver.resolve(path: skillPath, globalLockfile: skills, installedPlugins: installedPlugins([:]))

        #expect(origin == .repoInstall(
            source: "mattpocock/skills",
            skillFolderHash: "8320e7b87f7b208f50ce165b1dd43d1e93c8e801"
        ))
    }

    @Test func resolvesHandWrittenWhenNoTrackingDataMatches() {
        let skillPath = URL(fileURLWithPath: "/Users/aadhavan/.claude/skills/my-own-skill")

        let origin = SkillOriginResolver.resolve(
            path: skillPath,
            globalLockfile: lockfile([:]),
            installedPlugins: installedPlugins([:])
        )

        #expect(origin == .handWritten)
    }

    @Test func prioritizesPluginOriginOverRepoInstallWhenBothMatch() {
        let installPath = "/Users/aadhavan/.claude/plugins/cache/claude-plugins-official/grill-me/1.0.0"
        let skillPath = URL(fileURLWithPath: installPath)
        let plugins = installedPlugins([
            "grill-me@claude-plugins-official": [pluginEntry(installPath: installPath, version: "1.0.0")]
        ])
        let skills = lockfile(["grill-me": lockfileEntry()])

        let origin = SkillOriginResolver.resolve(path: skillPath, globalLockfile: skills, installedPlugins: plugins)

        #expect(origin == .plugin(name: "grill-me", marketplaceName: "claude-plugins-official", version: "1.0.0"))
    }

    @Test func doesNotFalsePositiveOnPathComponentPrefixCollision() {
        let installPath = "/Users/aadhavan/.claude/plugins/cache/claude-plugins-official/expo"
        let unrelatedSkillPath = URL(
            fileURLWithPath: "/Users/aadhavan/.claude/plugins/cache/claude-plugins-official/expo-extra/1.0.0/skill"
        )
        let plugins = installedPlugins([
            "expo@claude-plugins-official": [pluginEntry(installPath: installPath, version: "1.0.0")]
        ])

        let origin = SkillOriginResolver.resolve(
            path: unrelatedSkillPath,
            globalLockfile: lockfile([:]),
            installedPlugins: plugins
        )

        #expect(origin == .handWritten)
    }

    @Test func resolvesPluginOriginWhenInstallPathIsReachedThroughASymlinkedConfigDir() throws {
        let realBase = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: realBase) }
        let installDir = realBase.appendingPathComponent("plugins/cache/claude-plugins-official/superpowers/6.0.3")
        try FileManager.default.createDirectory(
            at: installDir.appendingPathComponent("skills/brainstorming"),
            withIntermediateDirectories: true
        )

        let symlinkBase = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createSymbolicLink(at: symlinkBase, withDestinationURL: realBase)
        defer { try? FileManager.default.removeItem(at: symlinkBase) }

        // SkillScanner always resolves symlinks before returning a DiscoveredSkill.path.
        let discoveredSkillPath = symlinkBase
            .appendingPathComponent("plugins/cache/claude-plugins-official/superpowers/6.0.3/skills/brainstorming")
            .resolvingSymlinksInPath()

        // installed_plugins.json stores the raw path exactly as configured, unresolved.
        let unresolvedInstallPath = symlinkBase
            .appendingPathComponent("plugins/cache/claude-plugins-official/superpowers/6.0.3").path
        let plugins = installedPlugins([
            "superpowers@claude-plugins-official": [pluginEntry(installPath: unresolvedInstallPath, version: "6.0.3")]
        ])

        let origin = SkillOriginResolver.resolve(
            path: discoveredSkillPath,
            globalLockfile: lockfile([:]),
            installedPlugins: plugins
        )

        #expect(origin == .plugin(name: "superpowers", marketplaceName: "claude-plugins-official", version: "6.0.3"))
    }
}
