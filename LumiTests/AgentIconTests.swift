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
}
