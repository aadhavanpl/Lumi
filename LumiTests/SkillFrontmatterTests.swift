//
//  SkillFrontmatterTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct SkillFrontmatterTests {

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

    @Test func parsesNameAndDescriptionFromValidFrontmatter() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("SKILL.md", in: root, contents: """
        ---
        name: frontend-design
        description: Guidance for distinctive, intentional visual design.
        license: Complete terms in LICENSE.txt
        ---

        # Frontend Design
        """)

        let frontmatter = SkillFrontmatter.parse(contentsOf: root.appendingPathComponent("SKILL.md"))

        #expect(frontmatter.name == "frontend-design")
        #expect(frontmatter.description == "Guidance for distinctive, intentional visual design.")
    }

    @Test func stripsMatchingQuotesFromYAMLQuotedScalarValues() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("SKILL.md", in: root, contents: """
        ---
        name: "imagegen"
        description: "Generate or edit raster images."
        ---
        """)

        let frontmatter = SkillFrontmatter.parse(contentsOf: root.appendingPathComponent("SKILL.md"))

        #expect(frontmatter.name == "imagegen")
        #expect(frontmatter.description == "Generate or edit raster images.")
    }

    @Test func returnsNilFieldsWhenFileDoesNotExist() {
        let missingPath = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("SKILL.md")

        let frontmatter = SkillFrontmatter.parse(contentsOf: missingPath)

        #expect(frontmatter.name == nil)
        #expect(frontmatter.description == nil)
    }

    @Test func returnsNilFieldsWhenFrontmatterDelimitersAreMissing() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("SKILL.md", in: root, contents: "# Just a heading, no frontmatter\n")

        let frontmatter = SkillFrontmatter.parse(contentsOf: root.appendingPathComponent("SKILL.md"))

        #expect(frontmatter.name == nil)
        #expect(frontmatter.description == nil)
    }

    @Test func ignoresFieldsOutsideNameAndDescription() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("SKILL.md", in: root, contents: """
        ---
        name: grill-me
        license: MIT
        ---
        """)

        let frontmatter = SkillFrontmatter.parse(contentsOf: root.appendingPathComponent("SKILL.md"))

        #expect(frontmatter.name == "grill-me")
        #expect(frontmatter.description == nil)
    }

    @Test func handlesDescriptionValuesContainingAColon() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("SKILL.md", in: root, contents: """
        ---
        name: grill-me
        description: Use when: the user wants to stress-test a plan.
        ---
        """)

        let frontmatter = SkillFrontmatter.parse(contentsOf: root.appendingPathComponent("SKILL.md"))

        #expect(frontmatter.description == "Use when: the user wants to stress-test a plan.")
    }

    @Test func fallsBackToNilWhenDescriptionUsesAYAMLBlockScalarIndicator() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try write("SKILL.md", in: root, contents: """
        ---
        name: grill-me
        description: >-
        ---
        """)

        let frontmatter = SkillFrontmatter.parse(contentsOf: root.appendingPathComponent("SKILL.md"))

        #expect(frontmatter.name == "grill-me")
        #expect(frontmatter.description == nil)
    }
}
