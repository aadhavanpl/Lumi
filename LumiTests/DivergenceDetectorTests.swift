//
//  DivergenceDetectorTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
import Testing
@testable import Lumi

struct DivergenceDetectorTests {

    private let globalCopy = SkillCopy(
        path: URL(fileURLWithPath: "/Users/aadhavan/.agents/skills/grill-me"),
        source: "mattpocock/skills",
        skillPath: "skills/productivity/grill-me/SKILL.md",
        contentHash: "current-hash"
    )
    private let projectCopy = SkillCopy(
        path: URL(fileURLWithPath: "/Users/aadhavan/Developer/abakon-abacus/.agents/skills/grill-me"),
        source: "mattpocock/skills",
        skillPath: "skills/productivity/grill-me/SKILL.md",
        contentHash: "june-fork-hash"
    )

    @Test func flagsDistinctCopiesOfTheSameUpstreamSkillWithDifferentContentAsDivergent() {
        let groups = DivergenceDetector.detect(copies: [globalCopy, projectCopy])

        #expect(groups.count == 1)
        let group = try! #require(groups.first)
        #expect(group.source == "mattpocock/skills")
        #expect(group.skillPath == "skills/productivity/grill-me/SKILL.md")
        #expect(Set(group.copies) == Set([globalCopy, projectCopy]))
    }

    @Test func doesNotFlagIdenticalCopiesAsDivergent() {
        let identicalProjectCopy = SkillCopy(
            path: projectCopy.path,
            source: projectCopy.source,
            skillPath: projectCopy.skillPath,
            contentHash: globalCopy.contentHash
        )

        #expect(DivergenceDetector.detect(copies: [globalCopy, identicalProjectCopy]).isEmpty)
    }

    @Test func doesNotFlagUnrelatedSkillsAsDivergent() {
        let unrelatedCopy = SkillCopy(
            path: URL(fileURLWithPath: "/Users/aadhavan/.agents/skills/improve"),
            source: "shadcn/improve",
            skillPath: "skills/improve/SKILL.md",
            contentHash: "some-other-hash"
        )

        #expect(DivergenceDetector.detect(copies: [globalCopy, unrelatedCopy]).isEmpty)
    }

    @Test func doesNotFlagASingleCopyAsDivergent() {
        #expect(DivergenceDetector.detect(copies: [globalCopy]).isEmpty)
    }
}
