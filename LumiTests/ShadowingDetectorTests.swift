//
//  ShadowingDetectorTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct ShadowingDetectorTests {

    private let globalPath = URL(fileURLWithPath: "/Users/aadhavan/.agents/skills/grill-me")
    private let projectRoot = URL(fileURLWithPath: "/Users/aadhavan/Developer/abakon-abacus")
    private let projectPath = URL(fileURLWithPath: "/Users/aadhavan/Developer/abakon-abacus/.agents/skills/grill-me")

    @Test func flagsProjectCopyAsShadowingGlobalCopyForSameNameAndAgent() throws {
        let discovered = [
            DiscoveredSkill(path: globalPath, agentID: "claude-code", scope: .global),
            DiscoveredSkill(path: projectPath, agentID: "claude-code", scope: .project(root: projectRoot))
        ]

        let shadowed = ShadowingDetector.detect(discovered: discovered)

        #expect(shadowed.count == 1)
        let result = try #require(shadowed.first)
        #expect(result.name == "grill-me")
        #expect(result.agentID == "claude-code")
        #expect(result.projectRoot == projectRoot)
        #expect(result.shadowingPath == projectPath)
        #expect(result.shadowedPath == globalPath)
    }

    @Test func reportsNothingWhenOnlyAGlobalCopyExists() {
        let discovered = [DiscoveredSkill(path: globalPath, agentID: "claude-code", scope: .global)]
        #expect(ShadowingDetector.detect(discovered: discovered).isEmpty)
    }

    @Test func reportsNothingWhenOnlyAProjectCopyExists() {
        let discovered = [
            DiscoveredSkill(path: projectPath, agentID: "claude-code", scope: .project(root: projectRoot))
        ]
        #expect(ShadowingDetector.detect(discovered: discovered).isEmpty)
    }

    @Test func doesNotFlagShadowingAcrossDifferentAgents() {
        let discovered = [
            DiscoveredSkill(path: globalPath, agentID: "claude-code", scope: .global),
            DiscoveredSkill(path: projectPath, agentID: "codex", scope: .project(root: projectRoot))
        ]
        #expect(ShadowingDetector.detect(discovered: discovered).isEmpty)
    }

    @Test func flagsOneShadowRecordPerProjectWhenMultipleProjectsShadowTheSameGlobalSkill() {
        let otherProjectRoot = URL(fileURLWithPath: "/Users/aadhavan/Developer/other-project")
        let otherProjectPath = otherProjectRoot.appendingPathComponent(".agents/skills/grill-me")
        let discovered = [
            DiscoveredSkill(path: globalPath, agentID: "claude-code", scope: .global),
            DiscoveredSkill(path: projectPath, agentID: "claude-code", scope: .project(root: projectRoot)),
            DiscoveredSkill(path: otherProjectPath, agentID: "claude-code", scope: .project(root: otherProjectRoot))
        ]

        let shadowed = ShadowingDetector.detect(discovered: discovered)

        #expect(shadowed.count == 2)
        #expect(Set(shadowed.map { $0.projectRoot }) == [projectRoot, otherProjectRoot])
    }
}
