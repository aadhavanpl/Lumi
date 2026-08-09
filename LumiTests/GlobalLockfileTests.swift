//
//  GlobalLockfileTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct GlobalLockfileTests {

    private let fixtureJSON = """
    {
      "version": 3,
      "skills": {
        "grill-me": {
          "source": "mattpocock/skills",
          "sourceType": "github",
          "sourceUrl": "https://github.com/mattpocock/skills.git",
          "skillPath": "skills/productivity/grill-me/SKILL.md",
          "skillFolderHash": "8320e7b87f7b208f50ce165b1dd43d1e93c8e801",
          "pluginName": "mattpocock-skills",
          "installedAt": "2026-06-25T16:51:13.669Z",
          "updatedAt": "2026-07-12T12:44:37.642Z"
        }
      },
      "dismissed": [],
      "lastSelectedAgents": ["claude-code"]
    }
    """

    @Test func decodesVersionAndSkillEntryFromReferenceFixture() throws {
        let lockfile = try GlobalLockfile.decode(from: Data(fixtureJSON.utf8))

        #expect(lockfile.version == 3)
        #expect(lockfile.lastSelectedAgents == ["claude-code"])
        #expect(lockfile.dismissed.isEmpty)

        let entry = try #require(lockfile.skills["grill-me"])
        #expect(entry.source == "mattpocock/skills")
        #expect(entry.sourceType == "github")
        #expect(entry.sourceUrl == "https://github.com/mattpocock/skills.git")
        #expect(entry.skillPath == "skills/productivity/grill-me/SKILL.md")
        #expect(entry.skillFolderHash == "8320e7b87f7b208f50ce165b1dd43d1e93c8e801")
        #expect(entry.pluginName == "mattpocock-skills")
    }

    @Test func decodesInstalledAtAsExactInstant() throws {
        let lockfile = try GlobalLockfile.decode(from: Data(fixtureJSON.utf8))
        let entry = try #require(lockfile.skills["grill-me"])

        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 25
        components.hour = 16
        components.minute = 51
        components.second = 13
        components.nanosecond = 669_000_000
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let expected = try #require(calendar.date(from: components))

        #expect(abs(entry.installedAt.timeIntervalSince(expected)) < 0.001)
    }

    @Test func defaultURLUsesXDGStateHomeWhenSet() {
        let url = GlobalLockfile.defaultURL(environment: ["XDG_STATE_HOME": "/tmp/state"])
        #expect(url.path == "/tmp/state/skills/.skill-lock.json")
    }

    @Test func defaultURLFallsBackToDotAgentsWhenXDGStateHomeUnset() {
        let url = GlobalLockfile.defaultURL(environment: [:])
        #expect(url.path == (NSHomeDirectory() as NSString).appendingPathComponent(".agents/.skill-lock.json"))
    }
}
