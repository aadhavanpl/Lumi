//
//  SkillFolderHasherTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
import Testing
@testable import Lumi

struct SkillFolderHasherTests {

    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func write(_ path: String, in root: URL, contents: String) throws {
        let url = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    @Test func hashesSingleFileAgainstIndependentlyComputedSHA256() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("SKILL.md", in: root, contents: "hello")

        let hash = try SkillFolderHasher.computeHash(at: root)

        #expect(hash == "15ee0148f7664b9a5220aef539c3b4f54947ff5f5b5a0779ac39a90546117982")
    }

    @Test func sortsMixedCaseFilenamesByCaseInsensitiveOrderNotCodePointOrder() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("SKILL.md", in: root, contents: "skill content")
        try write("references/note.md", in: root, contents: "a note")

        let hash = try SkillFolderHasher.computeHash(at: root)

        #expect(hash == "ead8f1a8d0217c9045abb42c283b6be732d7bd6552c41ffe680847e4be0be5c6")
        #expect(hash != "f78200b9dbbe072eafaa945c2f6af287581501faa1c6c845374a9891ea8081f3")
    }

    @Test func skipsGitAndNodeModulesDirectories() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("SKILL.md", in: root, contents: "hello")
        try write(".git/HEAD", in: root, contents: "ref: refs/heads/main")
        try write("node_modules/pkg/index.js", in: root, contents: "console.log(1)")

        let hash = try SkillFolderHasher.computeHash(at: root)

        #expect(hash == "15ee0148f7664b9a5220aef539c3b4f54947ff5f5b5a0779ac39a90546117982")
    }

    @Test func differentFileContentsProduceDifferentHashes() throws {
        let rootA = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: rootA) }
        try write("SKILL.md", in: rootA, contents: "version one")

        let rootB = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: rootB) }
        try write("SKILL.md", in: rootB, contents: "version two")

        let hashA = try SkillFolderHasher.computeHash(at: rootA)
        let hashB = try SkillFolderHasher.computeHash(at: rootB)

        #expect(hashA != hashB)
    }

    @Test func resolvesSymlinkedRootBeforeWalking() throws {
        let realRoot = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: realRoot) }
        try write("SKILL.md", in: realRoot, contents: "hello")

        let symlinkRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createSymbolicLink(at: symlinkRoot, withDestinationURL: realRoot)
        defer { try? FileManager.default.removeItem(at: symlinkRoot) }

        let directHash = try SkillFolderHasher.computeHash(at: realRoot)
        let symlinkedHash = try SkillFolderHasher.computeHash(at: symlinkRoot)

        #expect(directHash == symlinkedHash)
    }
}
