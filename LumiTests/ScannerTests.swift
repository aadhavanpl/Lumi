//
//  ScannerTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct ScannerTests {

    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func write(_ path: String, in root: URL, contents: String = "") throws {
        let url = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    @Test func findsADirectoryContainingSkillMD() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("my-skill/SKILL.md", in: root)

        let found = SkillScanner.findSkillDirectories(under: root)

        #expect(found.map(\.lastPathComponent) == ["my-skill"])
    }

    @Test func findsNestedSkillDirectories() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("category/nested-skill/SKILL.md", in: root)

        let found = SkillScanner.findSkillDirectories(under: root)

        #expect(found.map(\.lastPathComponent) == ["nested-skill"])
    }

    @Test func returnsEmptyForRootWithNoSkills() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("just-a-file.txt", in: root)

        let found = SkillScanner.findSkillDirectories(under: root)

        #expect(found.isEmpty)
    }

    @Test func returnsEmptyForNonexistentRoot() {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        let found = SkillScanner.findSkillDirectories(under: root)

        #expect(found.isEmpty)
    }

    @Test func skipsNoiseDirectories() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        for noisy in ["node_modules", ".git", "dist", "build", "__pycache__"] {
            try write("\(noisy)/should-not-count/SKILL.md", in: root)
        }
        try write("real-skill/SKILL.md", in: root)

        let found = SkillScanner.findSkillDirectories(under: root)

        #expect(found.map(\.lastPathComponent) == ["real-skill"])
    }

    @Test func resolvesSymlinksAndDedupesAgainstTheRealPath() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("real/actual-skill/SKILL.md", in: root)
        try FileManager.default.createSymbolicLink(
            at: root.appendingPathComponent("linked"),
            withDestinationURL: root.appendingPathComponent("real")
        )

        let found = SkillScanner.findSkillDirectories(under: root.appendingPathComponent("linked"))

        let resolvedReal = root.appendingPathComponent("real/actual-skill").resolvingSymlinksInPath()
        #expect(found == [resolvedReal])
    }
}
