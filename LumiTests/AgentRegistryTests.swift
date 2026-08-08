//
//  AgentRegistryTests.swift
//  LumiTests
//

import Foundation
import Testing
@testable import Lumi

struct AgentRegistryTests {

    private func agent(_ id: String, base: String = "~/.\(UUID().uuidString)") -> AgentDefinition {
        AgentDefinition(
            id: id,
            name: id,
            globalBase: base,
            globalBaseEnvOverride: nil,
            globalSkillsSubpath: "skills",
            projectSkillsDir: nil
        )
    }

    @Test func mergeWithNoOverridesReturnsDefaultsUnchanged() {
        let defaults = [agent("claude-code"), agent("codex")]

        let merged = AgentRegistry.merge(defaults: defaults, overrides: [])

        #expect(merged == defaults)
    }

    @Test func mergeReplacesDefaultWithMatchingOverrideID() {
        let defaults = [agent("claude-code", base: "~/.claude"), agent("codex", base: "~/.codex")]
        let override = agent("claude-code", base: "/custom/claude")

        let merged = AgentRegistry.merge(defaults: defaults, overrides: [override])

        #expect(merged.count == 2)
        #expect(merged[0].globalBase == "/custom/claude")
        #expect(merged[1] == defaults[1])
    }

    @Test func mergeAppendsOverrideWithNewID() {
        let defaults = [agent("claude-code")]
        let newAgent = agent("my-custom-agent")

        let merged = AgentRegistry.merge(defaults: defaults, overrides: [newAgent])

        #expect(merged == [defaults[0], newAgent])
    }

    @Test func bundledDefaultsContainsTheFiveVerifiedAgents() throws {
        let agents = try AgentRegistry.loadBundledDefaults()

        let byID = Dictionary(uniqueKeysWithValues: agents.map { ($0.id, $0) })
        #expect(byID.keys.sorted() == [
            "claude-code", "codex", "cursor", "github-copilot", "opencode"
        ])

        #expect(byID["claude-code"]?.globalSkillsURL(environment: [:]).path
                == NSString(string: "~/.claude/skills").expandingTildeInPath)
        #expect(byID["claude-code"]?.globalSkillsURL(environment: ["CLAUDE_CONFIG_DIR": "/x"]).path
                == "/x/skills")
        #expect(byID["claude-code"]?.projectSkillsDir == ".claude/skills")

        #expect(byID["codex"]?.globalSkillsURL(environment: [:]).path
                == NSString(string: "~/.codex/skills").expandingTildeInPath)
        #expect(byID["codex"]?.globalSkillsURL(environment: ["CODEX_HOME": "/x"]).path == "/x/skills")

        #expect(byID["cursor"]?.globalSkillsURL(environment: [:]).path
                == NSString(string: "~/.cursor/skills").expandingTildeInPath)
        #expect(byID["cursor"]?.projectSkillsDir == nil)

        #expect(byID["opencode"]?.globalSkillsURL(environment: [:]).path
                == NSString(string: "~/.config/opencode/skills").expandingTildeInPath)
        #expect(byID["opencode"]?.globalSkillsURL(environment: ["XDG_CONFIG_HOME": "/x"]).path
                == "/x/opencode/skills")

        #expect(byID["github-copilot"]?.globalSkillsURL(environment: [:]).path
                == NSString(string: "~/.copilot/skills").expandingTildeInPath)
        #expect(byID["github-copilot"]?.projectSkillsDir == nil)
    }

    private func withTempFile(contents: String?, _ body: (URL) throws -> Void) rethrows {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        if let contents {
            try? contents.write(to: url, atomically: true, encoding: .utf8)
        }
        try body(url)
    }

    @Test func loadUserOverridesReturnsEmptyWhenFileDoesNotExist() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")

        let overrides = AgentRegistry.loadUserOverrides(url: url)

        #expect(overrides.isEmpty)
    }

    @Test func loadUserOverridesReturnsEmptyWhenFileIsMalformed() {
        withTempFile(contents: "{ not valid json") { url in
            let overrides = AgentRegistry.loadUserOverrides(url: url)
            #expect(overrides.isEmpty)
        }
    }

    @Test func loadUserOverridesDecodesValidFile() {
        let json = """
        [{
            "id": "my-agent",
            "name": "My Agent",
            "globalBase": "~/.my-agent",
            "globalBaseEnvOverride": null,
            "globalSkillsSubpath": "skills",
            "projectSkillsDir": null
        }]
        """
        withTempFile(contents: json) { url in
            let overrides = AgentRegistry.loadUserOverrides(url: url)
            #expect(overrides.map(\.id) == ["my-agent"])
        }
    }
}
