//
//  AgentIconTests.swift
//  LumiTests
//
//  Created by Aadhavan on 09/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct AgentIconTests {

    @Test func mapsEachVerifiedAgentIDToADistinctAssetName() {
        let ids = ["claude-code", "codex", "cursor", "opencode", "github-copilot"]
        let names = Set(ids.map(AgentIcon.assetName(forAgentID:)))
        #expect(names.count == ids.count)
    }

    @Test func fallsBackToUnknownAssetForUnrecognizedAgentID() {
        #expect(AgentIcon.assetName(forAgentID: "some-future-agent") == "AgentIcon-Unknown")
    }

    @Test func mapsEachKnownAgentIDToItsProperCaseDisplayName() {
        #expect(AgentIcon.displayName(forAgentID: "claude-code") == "Claude Code")
        #expect(AgentIcon.displayName(forAgentID: "codex") == "Codex")
        #expect(AgentIcon.displayName(forAgentID: "cursor") == "Cursor")
        #expect(AgentIcon.displayName(forAgentID: "opencode") == "opencode")
        #expect(AgentIcon.displayName(forAgentID: "github-copilot") == "GitHub Copilot")
    }

    @Test func fallsBackToTheRawIDForAnUnrecognizedAgentID() {
        #expect(AgentIcon.displayName(forAgentID: "some-future-agent") == "some-future-agent")
    }

    @Test func mapsEachVerifiedAgentIDToADistinctBrandColor() {
        let ids = ["claude-code", "codex", "cursor", "opencode", "github-copilot"]
        let colors = Set(ids.map(AgentIcon.brandColor(forAgentID:)))
        #expect(colors.count == ids.count)
    }
}
