//
//  InventoryStoreTests.swift
//  LumiTests
//
//  Created by Aadhavan on 09/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct InventoryStoreTests {

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

    @Test func buildInventoryScansProjectSkillsUnderRegisteredWorkspaces() throws {
        let agentsRoot = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: agentsRoot) }
        let configRoot = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: configRoot) }
        let workspace = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }
        try write(".claude/skills/project-grill/SKILL.md", in: workspace, contents: """
        ---
        name: project-grill
        description: A project-scoped skill.
        ---
        """)

        let items = InventoryStore.buildInventory(
            registry: [agent("claude-code", base: agentsRoot.path, projectSkillsDir: ".claude/skills")],
            workspaces: [workspace],
            environment: ["CLAUDE_CONFIG_DIR": configRoot.path, "XDG_STATE_HOME": configRoot.path],
            fileManager: .default
        )

        #expect(items.count == 1)
        #expect(items[0].name == "project-grill")
        #expect(items[0].agentID == "claude-code")
        #expect(items[0].scope == .project(root: workspace))
    }

    @Test func buildInventoryWiresScannerAndBuilderTogetherEndToEnd() throws {
        let agentsRoot = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: agentsRoot) }
        try write("skills/grill-me/SKILL.md", in: agentsRoot, contents: """
        ---
        name: grill-me
        description: Interview the user relentlessly.
        ---
        """)
        let configRoot = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: configRoot) }

        let items = InventoryStore.buildInventory(
            registry: [agent("claude-code", base: agentsRoot.path)],
            environment: ["CLAUDE_CONFIG_DIR": configRoot.path, "XDG_STATE_HOME": configRoot.path],
            fileManager: .default
        )

        #expect(items.count == 1)
        #expect(items[0].name == "grill-me")
        #expect(items[0].origin == .handWritten)
    }

    @Test func refreshPopulatesItemsAndTogglesIsLoading() async throws {
        let agentsRoot = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: agentsRoot) }
        try write("skills/grill-me/SKILL.md", in: agentsRoot, contents: "")
        let configRoot = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: configRoot) }

        let store = await InventoryStore()
        #expect(await store.items.isEmpty)
        #expect(await store.isLoading == false)

        await store.refresh(
            registry: [agent("claude-code", base: agentsRoot.path)],
            environment: ["CLAUDE_CONFIG_DIR": configRoot.path, "XDG_STATE_HOME": configRoot.path],
            fileManager: .default
        )

        #expect(await store.items.count == 1)
        #expect(await store.isLoading == false)
    }
}
