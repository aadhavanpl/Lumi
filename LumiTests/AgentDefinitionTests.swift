//
//  AgentDefinitionTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct AgentDefinitionTests {

    @Test func decodesFromJSON() throws {
        let json = """
        {
            "id": "claude-code",
            "name": "Claude Code",
            "globalBase": "~/.claude",
            "globalBaseEnvOverride": "CLAUDE_CONFIG_DIR",
            "globalSkillsSubpath": "skills",
            "projectSkillsDir": ".claude/skills"
        }
        """

        let agent = try JSONDecoder().decode(AgentDefinition.self, from: Data(json.utf8))

        #expect(agent.id == "claude-code")
        #expect(agent.name == "Claude Code")
        #expect(agent.globalBase == "~/.claude")
        #expect(agent.globalBaseEnvOverride == "CLAUDE_CONFIG_DIR")
        #expect(agent.globalSkillsSubpath == "skills")
        #expect(agent.projectSkillsDir == ".claude/skills")
    }

    @Test func decodesWithoutProjectSkillsDir() throws {
        let json = """
        {
            "id": "cursor",
            "name": "Cursor",
            "globalBase": "~/.cursor",
            "globalBaseEnvOverride": null,
            "globalSkillsSubpath": "skills",
            "projectSkillsDir": null
        }
        """

        let agent = try JSONDecoder().decode(AgentDefinition.self, from: Data(json.utf8))

        #expect(agent.globalBaseEnvOverride == nil)
        #expect(agent.projectSkillsDir == nil)
    }

    @Test func globalSkillsURLUsesExpandedDefaultBaseWhenNoOverrideConfigured() {
        let agent = AgentDefinition(
            id: "cursor",
            name: "Cursor",
            globalBase: "~/.cursor",
            globalBaseEnvOverride: nil,
            globalSkillsSubpath: "skills",
            projectSkillsDir: nil
        )

        let url = agent.globalSkillsURL(environment: [:])

        #expect(url.path == NSString(string: "~/.cursor/skills").expandingTildeInPath)
    }

    @Test func globalSkillsURLUsesDefaultBaseWhenOverrideVarIsUnset() {
        let agent = AgentDefinition(
            id: "claude-code",
            name: "Claude Code",
            globalBase: "~/.claude",
            globalBaseEnvOverride: "CLAUDE_CONFIG_DIR",
            globalSkillsSubpath: "skills",
            projectSkillsDir: ".claude/skills"
        )

        let url = agent.globalSkillsURL(environment: [:])

        #expect(url.path == NSString(string: "~/.claude/skills").expandingTildeInPath)
    }

    @Test func globalSkillsURLUsesOverrideValueWhenEnvVarIsSet() {
        let agent = AgentDefinition(
            id: "claude-code",
            name: "Claude Code",
            globalBase: "~/.claude",
            globalBaseEnvOverride: "CLAUDE_CONFIG_DIR",
            globalSkillsSubpath: "skills",
            projectSkillsDir: ".claude/skills"
        )

        let url = agent.globalSkillsURL(environment: ["CLAUDE_CONFIG_DIR": "/custom/claude-config"])

        #expect(url.path == "/custom/claude-config/skills")
    }

    @Test func globalSkillsURLFallsBackToDefaultWhenOverrideVarIsEmpty() {
        let agent = AgentDefinition(
            id: "claude-code",
            name: "Claude Code",
            globalBase: "~/.claude",
            globalBaseEnvOverride: "CLAUDE_CONFIG_DIR",
            globalSkillsSubpath: "skills",
            projectSkillsDir: ".claude/skills"
        )

        let url = agent.globalSkillsURL(environment: ["CLAUDE_CONFIG_DIR": ""])

        #expect(url.path == NSString(string: "~/.claude/skills").expandingTildeInPath)
    }

    @Test func globalSkillsURLAppendsMultiComponentSubpath() {
        let agent = AgentDefinition(
            id: "opencode",
            name: "opencode",
            globalBase: "~/.config",
            globalBaseEnvOverride: "XDG_CONFIG_HOME",
            globalSkillsSubpath: "opencode/skills",
            projectSkillsDir: nil
        )

        let url = agent.globalSkillsURL(environment: [:])

        #expect(url.path == NSString(string: "~/.config/opencode/skills").expandingTildeInPath)
    }
}
