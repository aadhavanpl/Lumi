//
//  DiscoveredSkillScanTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
import Testing
@testable import Lumi

struct DiscoveredSkillScanTests {

    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func write(_ path: String, in root: URL, contents: String = "") throws {
        let url = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    private func agent(_ id: String, base: String, projectSkillsDir: String? = nil) -> AgentDefinition {
        AgentDefinition(
            id: id,
            name: id,
            globalBase: base,
            globalBaseEnvOverride: nil,
            globalSkillsSubpath: "skills",
            projectSkillsDir: projectSkillsDir
        )
    }

    @Test func scanGlobalSkillsFindsSkillsUnderEachAgentsResolvedDirectory() throws {
        let base = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: base) }
        try write("skills/my-skill/SKILL.md", in: base)

        let registry = [agent("claude-code", base: base.path)]
        let discovered = SkillScanner.scanGlobalSkills(registry: registry, environment: [:])

        #expect(discovered.count == 1)
        #expect(discovered[0].agentID == "claude-code")
        #expect(discovered[0].scope == .global)
        #expect(discovered[0].path.lastPathComponent == "my-skill")
    }

    @Test func scanGlobalSkillsReturnsNothingForAgentsWithNoSkills() {
        let base = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: base) }

        let registry = [agent("codex", base: base.path)]
        let discovered = SkillScanner.scanGlobalSkills(registry: registry, environment: [:])

        #expect(discovered.isEmpty)
    }

    @Test func scanProjectSkillsFindsSkillsUnderAgentsProjectDir() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write(".claude/skills/project-skill/SKILL.md", in: root)

        let registry = [agent("claude-code", base: "~/.claude", projectSkillsDir: ".claude/skills")]
        let discovered = SkillScanner.scanProjectSkills(registry: registry, projectRoots: [root])

        #expect(discovered.count == 1)
        #expect(discovered[0].agentID == "claude-code")
        #expect(discovered[0].scope == .project(root: root))
        #expect(discovered[0].path.lastPathComponent == "project-skill")
    }

    @Test func scanProjectSkillsSkipsAgentsWithNoProjectScope() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write(".cursor/skills/should-not-be-found/SKILL.md", in: root)

        let registry = [agent("cursor", base: "~/.cursor", projectSkillsDir: nil)]
        let discovered = SkillScanner.scanProjectSkills(registry: registry, projectRoots: [root])

        #expect(discovered.isEmpty)
    }

    @Test func scopeIsHashableForUseAsSetMembersAndDictionaryKeys() {
        let global = SkillScope.global
        let project = SkillScope.project(root: URL(fileURLWithPath: "/tmp/project"))
        let scopes: Set<SkillScope> = [global, project, .global]
        #expect(scopes.count == 2)
    }

    @Test func displayNameIsGlobalOrTheProjectDirectoryName() {
        #expect(SkillScope.global.displayName == "Global")
        let root = URL(fileURLWithPath: "/tmp/my-project")
        #expect(SkillScope.project(root: root).displayName == "my-project")
    }
}
