//
//  InstalledPluginsTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct InstalledPluginsTests {

    private let fixtureJSON = """
    {
      "version": 2,
      "plugins": {
        "expo@claude-plugins-official": [
          {
            "scope": "local",
            "projectPath": "/Users/aadhavan/Developer/networth",
            "installPath": "/Users/aadhavan/.claude/plugins/cache/claude-plugins-official/expo/1.0.0",
            "version": "1.0.0",
            "installedAt": "2026-04-21T09:08:13.855Z",
            "lastUpdated": "2026-04-21T09:08:13.855Z",
            "gitCommitSha": "8f26555fe105f72cf43051cf671771ad227a2f8f"
          }
        ],
        "swift-lsp@claude-plugins-official": [
          {
            "scope": "user",
            "installPath": "/Users/aadhavan/.claude/plugins/cache/claude-plugins-official/swift-lsp/1.0.0",
            "version": "1.0.0",
            "installedAt": "2026-06-05T11:41:03.040Z",
            "lastUpdated": "2026-06-05T11:41:03.040Z"
          }
        ]
      }
    }
    """

    @Test func decodesLocalScopedEntryWithProjectPathAndGitCommitSha() throws {
        let installed = try InstalledPlugins.decode(from: Data(fixtureJSON.utf8))

        #expect(installed.version == 2)

        let entries = try #require(installed.plugins["expo@claude-plugins-official"])
        let entry = try #require(entries.first)
        #expect(entry.scope == "local")
        #expect(entry.projectPath == "/Users/aadhavan/Developer/networth")
        #expect(entry.version == "1.0.0")
        #expect(entry.gitCommitSha == "8f26555fe105f72cf43051cf671771ad227a2f8f")
    }

    @Test func decodesUserScopedEntryWithoutProjectPathOrGitCommitSha() throws {
        let installed = try InstalledPlugins.decode(from: Data(fixtureJSON.utf8))

        let entries = try #require(installed.plugins["swift-lsp@claude-plugins-official"])
        let entry = try #require(entries.first)
        #expect(entry.scope == "user")
        #expect(entry.projectPath == nil)
        #expect(entry.gitCommitSha == nil)
    }

    @Test func defaultURLRespectsClaudeConfigDirOverride() {
        let url = InstalledPlugins.defaultURL(environment: ["CLAUDE_CONFIG_DIR": "/tmp/claude-home"])
        #expect(url.path == "/tmp/claude-home/plugins/installed_plugins.json")
    }

    @Test func defaultURLFallsBackToDotClaudeWhenUnset() {
        let url = InstalledPlugins.defaultURL(environment: [:])
        let expected = (NSHomeDirectory() as NSString).appendingPathComponent(".claude/plugins/installed_plugins.json")
        #expect(url.path == expected)
    }
}
