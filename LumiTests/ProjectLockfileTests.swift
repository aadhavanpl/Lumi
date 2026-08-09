//
//  ProjectLockfileTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct ProjectLockfileTests {

    private let fixtureJSON = """
    {
      "version": 1,
      "skills": {
        "frontend-design": {
          "source": "anthropics/skills",
          "sourceType": "github",
          "skillPath": "skills/frontend-design/SKILL.md",
          "computedHash": "4eabc66183767153e404b39d1b839b1c37f2d82d86f0a0d7e880a579d8d62336"
        }
      }
    }
    """

    @Test func decodesVersionAndSkillEntryFromReferenceFixture() throws {
        let lockfile = try ProjectLockfile.decode(from: Data(fixtureJSON.utf8))

        #expect(lockfile.version == 1)

        let entry = try #require(lockfile.skills["frontend-design"])
        #expect(entry.source == "anthropics/skills")
        #expect(entry.sourceType == "github")
        #expect(entry.skillPath == "skills/frontend-design/SKILL.md")
        #expect(entry.computedHash == "4eabc66183767153e404b39d1b839b1c37f2d82d86f0a0d7e880a579d8d62336")
    }

    @Test func urlForProjectRootHasNoLeadingDotAndSitsAtProjectRoot() {
        let root = URL(fileURLWithPath: "/tmp/my-project")
        let url = ProjectLockfile.url(forProjectRoot: root)

        #expect(url.path == "/tmp/my-project/skills-lock.json")
    }
}
