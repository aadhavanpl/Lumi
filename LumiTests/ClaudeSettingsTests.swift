//
//  ClaudeSettingsTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct ClaudeSettingsTests {

    @Test func decodesEnabledPluginsIgnoringUnrelatedTopLevelKeys() throws {
        let json = """
        {
          "env": {},
          "hooks": {},
          "enabledPlugins": {
            "superpowers@claude-plugins-official": true,
            "swift-lsp@claude-plugins-official": true
          },
          "extraKnownMarketplaces": {}
        }
        """
        let settings = try ClaudeSettings.decode(from: Data(json.utf8))

        #expect(settings.enabledPlugins == [
            "superpowers@claude-plugins-official": true,
            "swift-lsp@claude-plugins-official": true
        ])
    }

    @Test func decodesToEmptyDictionaryWhenEnabledPluginsKeyIsAbsent() throws {
        let json = "{ \"env\": {} }"
        let settings = try ClaudeSettings.decode(from: Data(json.utf8))

        #expect(settings.enabledPlugins.isEmpty)
    }

    @Test func defaultURLRespectsClaudeConfigDirOverride() {
        let url = ClaudeSettings.defaultURL(environment: ["CLAUDE_CONFIG_DIR": "/tmp/claude-home"])
        #expect(url.path == "/tmp/claude-home/settings.json")
    }

    @Test func defaultURLFallsBackToDotClaudeWhenUnset() {
        let url = ClaudeSettings.defaultURL(environment: [:])
        #expect(url.path == (NSHomeDirectory() as NSString).appendingPathComponent(".claude/settings.json"))
    }

    @Test func defaultInitProducesEmptyEnabledPlugins() {
        let settings = ClaudeSettings()
        #expect(settings.enabledPlugins.isEmpty)
    }

    @Test func defaultInitAcceptsAnExplicitDictionary() {
        let settings = ClaudeSettings(enabledPlugins: ["a@b": true])
        #expect(settings.enabledPlugins == ["a@b": true])
    }
}
