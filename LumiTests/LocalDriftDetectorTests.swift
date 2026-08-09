//
//  LocalDriftDetectorTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct LocalDriftDetectorTests {

    private func entry(computedHash: String) -> ProjectLockfileEntry {
        ProjectLockfileEntry(
            source: "anthropics/skills",
            sourceType: "github",
            skillPath: "skills/frontend-design/SKILL.md",
            computedHash: computedHash
        )
    }

    @Test func reportsNoDriftWhenComputedHashMatchesRecordedHash() {
        let hasDrifted = LocalDriftDetector.hasDrifted(computedHash: "abc123", entry: entry(computedHash: "abc123"))
        #expect(hasDrifted == false)
    }

    @Test func reportsDriftWhenComputedHashDiffersFromRecordedHash() {
        let hasDrifted = LocalDriftDetector.hasDrifted(computedHash: "abc123", entry: entry(computedHash: "def456"))
        #expect(hasDrifted == true)
    }
}
