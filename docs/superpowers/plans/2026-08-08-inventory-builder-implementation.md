# Inventory Builder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the correlation layer that joins scanner output with lockfile/plugin/marketplace
data into `[SkillInventoryItem]`, per
`docs/superpowers/specs/2026-08-08-inventory-builder-design.md` (approved, merged in PR #15).

**Architecture:** Four pure/best-effort pieces, each with its own file and TDD cycle, matching the
pattern already used for stages 2–5: a new `SkillFrontmatter` parser, a small addition to the
existing `Marketplace` parser, a new `SkillOriginResolver`, and a `SkillInventoryBuilder`
orchestrator that composes the other three plus the stage-5 `PluginCatalogDriftDetector`. Global
skills only — local drift, shadowing, and divergence are not wired in this round (they need
project-scope data that doesn't exist yet).

**Tech Stack:** Swift, Foundation only (no new dependencies — frontmatter parsing is two scalar
YAML fields, hand-rolled line parsing per YAGNI, not worth a YAML library), Swift Testing
(`import Testing`, `@Test`, `#expect`, `#require`), XCTest-free.

## Global Constraints

- Minimum deployment target is macOS 26.0 — no `#available` gating needed.
- SwiftLint runs `--strict` in CI; keep it green. Notably: `force_unwrapping` is an opt-in rule
  (no `!` on optionals in `Lumi/` — `LumiTests/` is excluded from lint entirely), `first_where` is
  opt-in (use `.first(where:)`, never `.filter{}.first`), line length warns at 120 / errors at 160.
- No comments unless they explain a non-obvious *why*; one line max.
- Lean and simple — no abstractions or config knobs for a single use site.
- Follow TDD strictly: write the failing test, run it, confirm it fails for the right reason, then
  write minimal code to pass.
- New Swift files need the header comment block matching existing files:
  `//\n//  File.swift\n//  Lumi\n//\n//  Created by Aadhavan on 08/08/26.\n//\n\n`.
- PR description: exactly `## Summary` and `## Test plan`, both short. No extra headers.
- Commit messages: one line, conventional (`feat:`/`fix:`/`chore:`). No `Co-Authored-By` trailer.
- Issue → branch → PR → review → merge. No direct pushes to `main`.
- Test command:
  `xcodebuild -project Lumi.xcodeproj -scheme Lumi -configuration Debug test -only-testing:LumiTests CODE_SIGNING_ALLOWED=NO`
- Lint command: `swiftlint lint --strict Lumi`

---

## File Structure

- Create: `Lumi/Parsers/SkillFrontmatter.swift` — parses `SKILL.md` frontmatter (`name` +
  `description` only).
- Modify: `Lumi/Parsers/Marketplace.swift` — add `Marketplace.discoveredURLs` extension.
- Create: `Lumi/Inventory/SkillOriginResolver.swift` — resolves plugin / repo-install /
  hand-written origin per skill (new `Lumi/Inventory/` directory, picked up automatically by the
  Xcode 16 file-system-synchronized group, no `project.pbxproj` edits needed).
- Create: `Lumi/Inventory/SkillInventoryBuilder.swift` — orchestrates the above into
  `[SkillInventoryItem]`.
- Create: `LumiTests/SkillFrontmatterTests.swift`
- Modify: `LumiTests/MarketplaceTests.swift` — add tests for `discoveredURLs`.
- Create: `LumiTests/SkillOriginResolverTests.swift`
- Create: `LumiTests/SkillInventoryBuilderTests.swift`

---

### Task 1: Project setup — issue and branch

**Files:** none (repo-level setup only)

- [ ] **Step 1: Create the GitHub issue**

```bash
gh issue create \
  --title "Inventory builder: frontmatter parser, origin resolver, correlation layer" \
  --body "Implements the design in docs/superpowers/specs/2026-08-08-inventory-builder-design.md (PR #15): SkillFrontmatter parser, Marketplace.discoveredURLs, SkillOriginResolver, SkillInventoryBuilder. Global skills only." \
  --label enhancement \
  --assignee "@me" \
  --milestone "V1"
```

Note the issue number printed in the URL — it's needed for the PR's `Closes #N` in Task 6.

- [ ] **Step 2: Create and switch to the feature branch**

```bash
git checkout main && git pull
git checkout -b feat/inventory-builder
```

---

### Task 2: `SkillFrontmatter` parser

**Files:**
- Create: `Lumi/Parsers/SkillFrontmatter.swift`
- Test: `LumiTests/SkillFrontmatterTests.swift`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  ```swift
  struct SkillFrontmatter: Equatable {
      let name: String?
      let description: String?
      static func parse(contentsOf skillMDPath: URL, fileManager: FileManager = .default) -> SkillFrontmatter
  }
  ```
  Later tasks call `SkillFrontmatter.parse(contentsOf:fileManager:)`.

- [ ] **Step 1: Write the failing tests**

Create `LumiTests/SkillFrontmatterTests.swift`:

```swift
//
//  SkillFrontmatterTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
import Testing
@testable import Lumi

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
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild -project Lumi.xcodeproj -scheme Lumi -configuration Debug test -only-testing:LumiTests/SkillFrontmatterTests CODE_SIGNING_ALLOWED=NO`
Expected: FAIL to build — `SkillFrontmatter` is not defined.

- [ ] **Step 3: Write the implementation**

Create `Lumi/Parsers/SkillFrontmatter.swift`:

```swift
//
//  SkillFrontmatter.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

struct SkillFrontmatter: Equatable {
    let name: String?
    let description: String?

    static func parse(contentsOf skillMDPath: URL, fileManager: FileManager = .default) -> SkillFrontmatter {
        guard let data = fileManager.contents(atPath: skillMDPath.path),
              let contents = String(data: data, encoding: .utf8) else {
            return SkillFrontmatter(name: nil, description: nil)
        }
        return parse(contents)
    }

    private static func parse(_ contents: String) -> SkillFrontmatter {
        let lines = contents.components(separatedBy: .newlines)
        guard lines.first == "---",
              let closingIndex = lines.dropFirst().firstIndex(of: "---") else {
            return SkillFrontmatter(name: nil, description: nil)
        }

        var name: String?
        var description: String?
        for line in lines[1..<closingIndex] {
            guard let colonIndex = line.firstIndex(of: ":") else { continue }
            let key = line[line.startIndex..<colonIndex].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
            guard !value.isEmpty else { continue }

            switch key {
            case "name": name = value
            case "description": description = value
            default: break
            }
        }
        return SkillFrontmatter(name: name, description: description)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild -project Lumi.xcodeproj -scheme Lumi -configuration Debug test -only-testing:LumiTests/SkillFrontmatterTests CODE_SIGNING_ALLOWED=NO`
Expected: PASS, all 5 tests.

- [ ] **Step 5: Lint and commit**

```bash
swiftlint lint --strict Lumi
git add Lumi/Parsers/SkillFrontmatter.swift LumiTests/SkillFrontmatterTests.swift
git commit -m "feat: add SKILL.md frontmatter parser"
```

---

### Task 3: `Marketplace.discoveredURLs`

**Files:**
- Modify: `Lumi/Parsers/Marketplace.swift` (append extension)
- Modify: `LumiTests/MarketplaceTests.swift` (append tests + helpers)

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  ```swift
  extension Marketplace {
      static func discoveredURLs(
          environment: [String: String] = ProcessInfo.processInfo.environment,
          fileManager: FileManager = .default
      ) -> [URL]
  }
  ```
  Returns `.claude-plugin/marketplace.json` file URLs (not directories) — later tasks decode each
  with the existing `Marketplace.decode(from:)`.

- [ ] **Step 1: Write the failing tests**

Add to `LumiTests/MarketplaceTests.swift`, inside the existing `MarketplaceTests` struct, after
`fixtureJSON`:

```swift
    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func write(_ path: String, in root: URL, contents: String = "{}") throws {
        let url = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    @Test func discoveredURLsFindsMarketplaceJSONUnderEachMarketplaceDirectory() throws {
        let configDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: configDir) }
        try write("plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json", in: configDir)
        try write("plugins/marketplaces/expo-plugins/.claude-plugin/marketplace.json", in: configDir)

        let urls = Marketplace.discoveredURLs(environment: ["CLAUDE_CONFIG_DIR": configDir.path])

        #expect(Set(urls.map(\.path)) == Set([
            configDir.appendingPathComponent("plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json").path,
            configDir.appendingPathComponent("plugins/marketplaces/expo-plugins/.claude-plugin/marketplace.json").path
        ]))
    }

    @Test func discoveredURLsSkipsMarketplaceDirectoriesMissingMarketplaceJSON() throws {
        let configDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: configDir) }
        try write("plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json", in: configDir)
        try FileManager.default.createDirectory(
            at: configDir.appendingPathComponent("plugins/marketplaces/empty-marketplace"),
            withIntermediateDirectories: true
        )

        let urls = Marketplace.discoveredURLs(environment: ["CLAUDE_CONFIG_DIR": configDir.path])

        #expect(urls.map(\.path) == [
            configDir.appendingPathComponent("plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json").path
        ])
    }

    @Test func discoveredURLsReturnsEmptyWhenMarketplacesDirectoryDoesNotExist() {
        let configDir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: configDir) }

        let urls = Marketplace.discoveredURLs(environment: ["CLAUDE_CONFIG_DIR": configDir.path])

        #expect(urls.isEmpty)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild -project Lumi.xcodeproj -scheme Lumi -configuration Debug test -only-testing:LumiTests/MarketplaceTests CODE_SIGNING_ALLOWED=NO`
Expected: FAIL to build — `Marketplace.discoveredURLs` is not defined.

- [ ] **Step 3: Write the implementation**

Append to `Lumi/Parsers/Marketplace.swift`:

```swift

extension Marketplace {
    static func discoveredURLs(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> [URL] {
        let override = environment["CLAUDE_CONFIG_DIR"].flatMap { $0.isEmpty ? nil : $0 }
        let base = override ?? (NSHomeDirectory() as NSString).appendingPathComponent(".claude")
        let marketplacesDir = URL(fileURLWithPath: base)
            .appendingPathComponent("plugins")
            .appendingPathComponent("marketplaces")
            .resolvingSymlinksInPath()

        guard let entries = try? fileManager.contentsOfDirectory(
            at: marketplacesDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else {
            return []
        }

        return entries
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
            .map { $0.appendingPathComponent(".claude-plugin").appendingPathComponent("marketplace.json") }
            .filter { fileManager.fileExists(atPath: $0.path) }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild -project Lumi.xcodeproj -scheme Lumi -configuration Debug test -only-testing:LumiTests/MarketplaceTests CODE_SIGNING_ALLOWED=NO`
Expected: PASS, all tests including the 3 new ones.

- [ ] **Step 5: Lint and commit**

```bash
swiftlint lint --strict Lumi
git add Lumi/Parsers/Marketplace.swift LumiTests/MarketplaceTests.swift
git commit -m "feat: discover registered marketplace catalog files"
```

---

### Task 4: `SkillOriginResolver`

**Files:**
- Create: `Lumi/Inventory/SkillOriginResolver.swift`
- Test: `LumiTests/SkillOriginResolverTests.swift`

**Interfaces:**
- Consumes: `GlobalLockfile` / `GlobalLockfileEntry` (`Lumi/Parsers/GlobalLockfile.swift`),
  `InstalledPlugins` / `InstalledPluginEntry` (`Lumi/Parsers/InstalledPlugins.swift`).
- Produces:
  ```swift
  enum SkillOrigin: Equatable {
      case plugin(name: String, marketplaceName: String, version: String)
      case repoInstall(source: String, skillFolderHash: String)
      case handWritten
  }

  enum SkillOriginResolver {
      static func resolve(
          path: URL,
          globalLockfile: GlobalLockfile,
          installedPlugins: InstalledPlugins
      ) -> SkillOrigin
  }
  ```
  Later tasks call `SkillOriginResolver.resolve(path:globalLockfile:installedPlugins:)` and switch
  on `SkillOrigin`.

- [ ] **Step 1: Write the failing tests**

Create `LumiTests/SkillOriginResolverTests.swift`:

```swift
//
//  SkillOriginResolverTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
import Testing
@testable import Lumi

struct SkillOriginResolverTests {

    private func installedPlugins(_ entries: [String: [InstalledPluginEntry]]) -> InstalledPlugins {
        InstalledPlugins(version: 2, plugins: entries)
    }

    private func pluginEntry(installPath: String, version: String = "1.0.0") -> InstalledPluginEntry {
        InstalledPluginEntry(
            scope: "user",
            projectPath: nil,
            installPath: installPath,
            version: version,
            installedAt: Date(),
            lastUpdated: Date(),
            gitCommitSha: nil
        )
    }

    private func lockfile(_ skills: [String: GlobalLockfileEntry]) -> GlobalLockfile {
        GlobalLockfile(version: 3, skills: skills, dismissed: [], lastSelectedAgents: [])
    }

    private func lockfileEntry(
        source: String = "mattpocock/skills",
        skillFolderHash: String = "8320e7b87f7b208f50ce165b1dd43d1e93c8e801"
    ) -> GlobalLockfileEntry {
        GlobalLockfileEntry(
            source: source,
            sourceType: "github",
            sourceUrl: "https://github.com/mattpocock/skills.git",
            skillPath: "skills/productivity/grill-me/SKILL.md",
            skillFolderHash: skillFolderHash,
            pluginName: nil,
            installedAt: Date(),
            updatedAt: Date()
        )
    }

    @Test func resolvesPluginOriginWhenPathIsContainedUnderInstallPath() {
        let installPath = "/Users/aadhavan/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.3"
        let skillPath = URL(fileURLWithPath: "\(installPath)/skills/brainstorming")
        let plugins = installedPlugins([
            "superpowers@claude-plugins-official": [pluginEntry(installPath: installPath, version: "6.0.3")]
        ])

        let origin = SkillOriginResolver.resolve(path: skillPath, globalLockfile: lockfile([:]), installedPlugins: plugins)

        #expect(origin == .plugin(name: "superpowers", marketplaceName: "claude-plugins-official", version: "6.0.3"))
    }

    @Test func resolvesRepoInstallOriginWhenDirectoryNameMatchesLockfileKey() {
        let skillPath = URL(fileURLWithPath: "/Users/aadhavan/.agents/skills/grill-me")
        let skills = lockfile(["grill-me": lockfileEntry()])

        let origin = SkillOriginResolver.resolve(path: skillPath, globalLockfile: skills, installedPlugins: installedPlugins([:]))

        #expect(origin == .repoInstall(
            source: "mattpocock/skills",
            skillFolderHash: "8320e7b87f7b208f50ce165b1dd43d1e93c8e801"
        ))
    }

    @Test func resolvesHandWrittenWhenNoTrackingDataMatches() {
        let skillPath = URL(fileURLWithPath: "/Users/aadhavan/.claude/skills/my-own-skill")

        let origin = SkillOriginResolver.resolve(
            path: skillPath,
            globalLockfile: lockfile([:]),
            installedPlugins: installedPlugins([:])
        )

        #expect(origin == .handWritten)
    }

    @Test func prioritizesPluginOriginOverRepoInstallWhenBothMatch() {
        let installPath = "/Users/aadhavan/.claude/plugins/cache/claude-plugins-official/grill-me/1.0.0"
        let skillPath = URL(fileURLWithPath: installPath)
        let plugins = installedPlugins([
            "grill-me@claude-plugins-official": [pluginEntry(installPath: installPath, version: "1.0.0")]
        ])
        let skills = lockfile(["grill-me": lockfileEntry()])

        let origin = SkillOriginResolver.resolve(path: skillPath, globalLockfile: skills, installedPlugins: plugins)

        #expect(origin == .plugin(name: "grill-me", marketplaceName: "claude-plugins-official", version: "1.0.0"))
    }

    @Test func doesNotFalsePositiveOnPathComponentPrefixCollision() {
        let installPath = "/Users/aadhavan/.claude/plugins/cache/claude-plugins-official/expo"
        let unrelatedSkillPath = URL(
            fileURLWithPath: "/Users/aadhavan/.claude/plugins/cache/claude-plugins-official/expo-extra/1.0.0/skill"
        )
        let plugins = installedPlugins([
            "expo@claude-plugins-official": [pluginEntry(installPath: installPath, version: "1.0.0")]
        ])

        let origin = SkillOriginResolver.resolve(
            path: unrelatedSkillPath,
            globalLockfile: lockfile([:]),
            installedPlugins: plugins
        )

        #expect(origin == .handWritten)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild -project Lumi.xcodeproj -scheme Lumi -configuration Debug test -only-testing:LumiTests/SkillOriginResolverTests CODE_SIGNING_ALLOWED=NO`
Expected: FAIL to build — `SkillOriginResolver` / `SkillOrigin` not defined.

- [ ] **Step 3: Write the implementation**

Create `Lumi/Inventory/SkillOriginResolver.swift`:

```swift
//
//  SkillOriginResolver.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

enum SkillOrigin: Equatable {
    case plugin(name: String, marketplaceName: String, version: String)
    case repoInstall(source: String, skillFolderHash: String)
    case handWritten
}

/// Plugin match is a path-containment check (unambiguous); the lockfile match is a name lookup
/// that could theoretically collide, so plugin is checked first.
enum SkillOriginResolver {
    static func resolve(
        path: URL,
        globalLockfile: GlobalLockfile,
        installedPlugins: InstalledPlugins
    ) -> SkillOrigin {
        if let origin = resolvePlugin(path: path, installedPlugins: installedPlugins) {
            return origin
        }
        if let entry = globalLockfile.skills[path.lastPathComponent] {
            return .repoInstall(source: entry.source, skillFolderHash: entry.skillFolderHash)
        }
        return .handWritten
    }

    private static func resolvePlugin(path: URL, installedPlugins: InstalledPlugins) -> SkillOrigin? {
        let pathComponents = path.pathComponents

        for (key, entries) in installedPlugins.plugins {
            guard let atIndex = key.firstIndex(of: "@") else { continue }
            let pluginName = String(key[key.startIndex..<atIndex])
            let marketplaceName = String(key[key.index(after: atIndex)...])

            guard let entry = entries.first(where: {
                isContained(URL(fileURLWithPath: $0.installPath).pathComponents, in: pathComponents)
            }) else { continue }

            return .plugin(name: pluginName, marketplaceName: marketplaceName, version: entry.version)
        }
        return nil
    }

    /// Compares path components, not a raw string prefix — `hasPrefix` false-positives `/a/b` on `/a/bc`.
    private static func isContained(_ installPathComponents: [String], in pathComponents: [String]) -> Bool {
        installPathComponents.count <= pathComponents.count
            && Array(pathComponents.prefix(installPathComponents.count)) == installPathComponents
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild -project Lumi.xcodeproj -scheme Lumi -configuration Debug test -only-testing:LumiTests/SkillOriginResolverTests CODE_SIGNING_ALLOWED=NO`
Expected: PASS, all 5 tests.

- [ ] **Step 5: Lint and commit**

```bash
swiftlint lint --strict Lumi
git add Lumi/Inventory/SkillOriginResolver.swift LumiTests/SkillOriginResolverTests.swift
git commit -m "feat: add plugin/repo-install/hand-written origin resolver"
```

---

### Task 5: `SkillInventoryBuilder`

**Files:**
- Create: `Lumi/Inventory/SkillInventoryBuilder.swift`
- Test: `LumiTests/SkillInventoryBuilderTests.swift`

**Interfaces:**
- Consumes: `DiscoveredSkill` / `SkillScope` (`Lumi/Scanner/DiscoveredSkill.swift`),
  `GlobalLockfile` / `GlobalLockfileEntry`, `InstalledPlugins` / `InstalledPluginEntry`,
  `ClaudeSettings`, `Marketplace` / `MarketplacePlugin` / `MarketplacePluginSource` /
  `PinnedMarketplaceSource`, `PluginCatalogDriftDetector` / `PluginCatalogDriftStatus`
  (`Lumi/Detection/PluginCatalogDriftDetector.swift`), `SkillOrigin` / `SkillOriginResolver`
  (Task 4), `SkillFrontmatter` (Task 2).
- Produces:
  ```swift
  struct SkillInventoryItem: Equatable {
      let name: String
      let description: String?
      let path: URL
      let agentID: String
      let scope: SkillScope
      let origin: SkillOrigin
      let statuses: [SkillStatus]
  }

  enum SkillStatus: Equatable {
      case pluginCatalogDrifted(installedSha: String, pinnedSha: String)
      case installedButDisabled
  }

  enum SkillInventoryBuilder {
      static func build(
          discovered: [DiscoveredSkill],
          globalLockfile: GlobalLockfile,
          installedPlugins: InstalledPlugins,
          settings: ClaudeSettings,
          marketplaces: [Marketplace],
          fileManager: FileManager = .default
      ) -> [SkillInventoryItem]
  }
  ```
  This is the entry point the future UI-layer `InventoryStore` will call.

- [ ] **Step 1: Write the failing tests**

Create `LumiTests/SkillInventoryBuilderTests.swift`:

```swift
//
//  SkillInventoryBuilderTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
import Testing
@testable import Lumi

struct SkillInventoryBuilderTests {

    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func writeSkillMD(in skillDir: URL, name: String? = nil, description: String? = nil) throws {
        try FileManager.default.createDirectory(at: skillDir, withIntermediateDirectories: true)
        var frontmatter = "---\n"
        if let name { frontmatter += "name: \(name)\n" }
        if let description { frontmatter += "description: \(description)\n" }
        frontmatter += "---\n"
        try frontmatter.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)
    }

    private func emptyLockfile() -> GlobalLockfile {
        GlobalLockfile(version: 3, skills: [:], dismissed: [], lastSelectedAgents: [])
    }

    private func emptyInstalledPlugins() -> InstalledPlugins {
        InstalledPlugins(version: 2, plugins: [:])
    }

    private func emptySettings() throws -> ClaudeSettings {
        try ClaudeSettings.decode(from: Data("{}".utf8))
    }

    @Test func buildsHandWrittenItemUsingFrontmatterNameAndDescription() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let skillDir = root.appendingPathComponent("grill-me")
        try writeSkillMD(in: skillDir, name: "grill-me", description: "Interview the user relentlessly.")
        let discovered = [DiscoveredSkill(path: skillDir, agentID: "claude-code", scope: .global)]

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: emptyLockfile(),
            installedPlugins: emptyInstalledPlugins(),
            settings: try emptySettings(),
            marketplaces: []
        )

        #expect(items.count == 1)
        #expect(items[0].name == "grill-me")
        #expect(items[0].description == "Interview the user relentlessly.")
        #expect(items[0].origin == .handWritten)
        #expect(items[0].statuses.isEmpty)
    }

    @Test func fallsBackToDirectoryNameWhenFrontmatterNameIsMissing() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let skillDir = root.appendingPathComponent("undocumented-skill")
        try FileManager.default.createDirectory(at: skillDir, withIntermediateDirectories: true)
        let discovered = [DiscoveredSkill(path: skillDir, agentID: "claude-code", scope: .global)]

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: emptyLockfile(),
            installedPlugins: emptyInstalledPlugins(),
            settings: try emptySettings(),
            marketplaces: []
        )

        #expect(items[0].name == "undocumented-skill")
        #expect(items[0].description == nil)
    }

    @Test func resolvesPluginOriginAndCarriesVersion() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let installPath = root.appendingPathComponent("plugins/cache/claude-plugins-official/superpowers/6.0.3")
        let skillDir = installPath.appendingPathComponent("skills/brainstorming")
        try writeSkillMD(in: skillDir, name: "brainstorming")
        let discovered = [DiscoveredSkill(path: skillDir, agentID: "claude-code", scope: .global)]
        let plugins = InstalledPlugins(version: 2, plugins: [
            "superpowers@claude-plugins-official": [InstalledPluginEntry(
                scope: "user",
                projectPath: nil,
                installPath: installPath.path,
                version: "6.0.3",
                installedAt: Date(),
                lastUpdated: Date(),
                gitCommitSha: "896224c4b1879920ab573417e68fd51d2ccc9072"
            )]
        ])

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: emptyLockfile(),
            installedPlugins: plugins,
            settings: try emptySettings(),
            marketplaces: []
        )

        #expect(items[0].origin == .plugin(name: "superpowers", marketplaceName: "claude-plugins-official", version: "6.0.3"))
    }

    @Test func flagsPluginCatalogDriftedStatusWhenInstalledShaDiffersFromPinnedSha() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let installPath = root.appendingPathComponent("plugins/cache/claude-plugins-official/superpowers/6.0.3")
        try writeSkillMD(in: installPath, name: "superpowers")
        let discovered = [DiscoveredSkill(path: installPath, agentID: "claude-code", scope: .global)]
        let plugins = InstalledPlugins(version: 2, plugins: [
            "superpowers@claude-plugins-official": [InstalledPluginEntry(
                scope: "user",
                projectPath: nil,
                installPath: installPath.path,
                version: "6.0.3",
                installedAt: Date(),
                lastUpdated: Date(),
                gitCommitSha: "6fd4507659784c351abbd2bc264c7162cfd386dc"
            )]
        ])
        let marketplace = Marketplace(name: "claude-plugins-official", plugins: [
            MarketplacePlugin(name: "superpowers", category: "development", source: .pinned(PinnedMarketplaceSource(
                kind: "url",
                url: "https://github.com/obra/superpowers.git",
                path: nil,
                ref: nil,
                sha: "896224c4b1879920ab573417e68fd51d2ccc9072"
            )))
        ])
        let settings = try ClaudeSettings.decode(from: Data("""
        { "enabledPlugins": { "superpowers@claude-plugins-official": true } }
        """.utf8))

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: emptyLockfile(),
            installedPlugins: plugins,
            settings: settings,
            marketplaces: [marketplace]
        )

        #expect(items[0].statuses == [.pluginCatalogDrifted(
            installedSha: "6fd4507659784c351abbd2bc264c7162cfd386dc",
            pinnedSha: "896224c4b1879920ab573417e68fd51d2ccc9072"
        )])
    }

    @Test func flagsInstalledButDisabledStatusWhenSettingsKeyIsMissing() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let installPath = root.appendingPathComponent("plugins/cache/claude-plugins-official/swift-lsp/1.0.0")
        try writeSkillMD(in: installPath, name: "swift-lsp")
        let discovered = [DiscoveredSkill(path: installPath, agentID: "claude-code", scope: .global)]
        let plugins = InstalledPlugins(version: 2, plugins: [
            "swift-lsp@claude-plugins-official": [InstalledPluginEntry(
                scope: "user",
                projectPath: nil,
                installPath: installPath.path,
                version: "1.0.0",
                installedAt: Date(),
                lastUpdated: Date(),
                gitCommitSha: nil
            )]
        ])

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: emptyLockfile(),
            installedPlugins: plugins,
            settings: try emptySettings(),
            marketplaces: []
        )

        #expect(items[0].statuses == [.installedButDisabled])
    }

    @Test func producesNoStatusesForRepoInstallOrigin() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let skillDir = root.appendingPathComponent("grill-me")
        try writeSkillMD(in: skillDir, name: "grill-me")
        let discovered = [DiscoveredSkill(path: skillDir, agentID: "claude-code", scope: .global)]
        let lockfile = GlobalLockfile(version: 3, skills: [
            "grill-me": GlobalLockfileEntry(
                source: "mattpocock/skills",
                sourceType: "github",
                sourceUrl: "https://github.com/mattpocock/skills.git",
                skillPath: "skills/productivity/grill-me/SKILL.md",
                skillFolderHash: "8320e7b87f7b208f50ce165b1dd43d1e93c8e801",
                pluginName: nil,
                installedAt: Date(),
                updatedAt: Date()
            )
        ], dismissed: [], lastSelectedAgents: [])

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: lockfile,
            installedPlugins: emptyInstalledPlugins(),
            settings: try emptySettings(),
            marketplaces: []
        )

        #expect(items[0].origin == .repoInstall(
            source: "mattpocock/skills",
            skillFolderHash: "8320e7b87f7b208f50ce165b1dd43d1e93c8e801"
        ))
        #expect(items[0].statuses.isEmpty)
    }

    @Test func producesNoDriftStatusWhenPluginsMarketplaceIsNotInScannedSet() throws {
        let root = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let installPath = root.appendingPathComponent("plugins/cache/claude-plugins-official/superpowers/6.0.3")
        try writeSkillMD(in: installPath, name: "superpowers")
        let discovered = [DiscoveredSkill(path: installPath, agentID: "claude-code", scope: .global)]
        let plugins = InstalledPlugins(version: 2, plugins: [
            "superpowers@claude-plugins-official": [InstalledPluginEntry(
                scope: "user",
                projectPath: nil,
                installPath: installPath.path,
                version: "6.0.3",
                installedAt: Date(),
                lastUpdated: Date(),
                gitCommitSha: "6fd4507659784c351abbd2bc264c7162cfd386dc"
            )]
        ])
        let settings = try ClaudeSettings.decode(from: Data("""
        { "enabledPlugins": { "superpowers@claude-plugins-official": true } }
        """.utf8))

        let items = SkillInventoryBuilder.build(
            discovered: discovered,
            globalLockfile: emptyLockfile(),
            installedPlugins: plugins,
            settings: settings,
            marketplaces: []
        )

        #expect(items[0].statuses.isEmpty)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild -project Lumi.xcodeproj -scheme Lumi -configuration Debug test -only-testing:LumiTests/SkillInventoryBuilderTests CODE_SIGNING_ALLOWED=NO`
Expected: FAIL to build — `SkillInventoryBuilder` / `SkillInventoryItem` / `SkillStatus` not defined.

- [ ] **Step 3: Write the implementation**

Create `Lumi/Inventory/SkillInventoryBuilder.swift`:

```swift
//
//  SkillInventoryBuilder.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

struct SkillInventoryItem: Equatable {
    let name: String
    let description: String?
    let path: URL
    let agentID: String
    let scope: SkillScope
    let origin: SkillOrigin
    let statuses: [SkillStatus]
}

enum SkillStatus: Equatable {
    case pluginCatalogDrifted(installedSha: String, pinnedSha: String)
    case installedButDisabled
}

enum SkillInventoryBuilder {
    static func build(
        discovered: [DiscoveredSkill],
        globalLockfile: GlobalLockfile,
        installedPlugins: InstalledPlugins,
        settings: ClaudeSettings,
        marketplaces: [Marketplace],
        fileManager: FileManager = .default
    ) -> [SkillInventoryItem] {
        discovered.map {
            buildItem(
                for: $0,
                globalLockfile: globalLockfile,
                installedPlugins: installedPlugins,
                settings: settings,
                marketplaces: marketplaces,
                fileManager: fileManager
            )
        }
    }

    private static func buildItem(
        for skill: DiscoveredSkill,
        globalLockfile: GlobalLockfile,
        installedPlugins: InstalledPlugins,
        settings: ClaudeSettings,
        marketplaces: [Marketplace],
        fileManager: FileManager
    ) -> SkillInventoryItem {
        let origin = SkillOriginResolver.resolve(
            path: skill.path,
            globalLockfile: globalLockfile,
            installedPlugins: installedPlugins
        )
        let frontmatter = SkillFrontmatter.parse(
            contentsOf: skill.path.appendingPathComponent("SKILL.md"),
            fileManager: fileManager
        )

        return SkillInventoryItem(
            name: frontmatter.name ?? skill.path.lastPathComponent,
            description: frontmatter.description,
            path: skill.path,
            agentID: skill.agentID,
            scope: skill.scope,
            origin: origin,
            statuses: statuses(
                for: origin,
                installedPlugins: installedPlugins,
                settings: settings,
                marketplaces: marketplaces
            )
        )
    }

    private static func statuses(
        for origin: SkillOrigin,
        installedPlugins: InstalledPlugins,
        settings: ClaudeSettings,
        marketplaces: [Marketplace]
    ) -> [SkillStatus] {
        guard case .plugin(let name, let marketplaceName, let version) = origin else { return [] }

        var statuses: [SkillStatus] = []
        let key = "\(name)@\(marketplaceName)"

        if let entry = installedPlugins.plugins[key]?.first(where: { $0.version == version }),
           let marketplace = marketplaces.first(where: { $0.name == marketplaceName }),
           case .drifted(let installedSha, let pinnedSha) = PluginCatalogDriftDetector.detect(
               pluginName: name,
               installed: entry,
               marketplace: marketplace
           ) {
            statuses.append(.pluginCatalogDrifted(installedSha: installedSha, pinnedSha: pinnedSha))
        }

        if settings.enabledPlugins[key] != true {
            statuses.append(.installedButDisabled)
        }

        return statuses
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild -project Lumi.xcodeproj -scheme Lumi -configuration Debug test -only-testing:LumiTests/SkillInventoryBuilderTests CODE_SIGNING_ALLOWED=NO`
Expected: PASS, all 7 tests.

- [ ] **Step 5: Lint and commit**

```bash
swiftlint lint --strict Lumi
git add Lumi/Inventory/SkillInventoryBuilder.swift LumiTests/SkillInventoryBuilderTests.swift
git commit -m "feat: add inventory builder correlating scanner, lockfile, and plugin data"
```

---

### Task 6: Full suite, lint, and PR

**Files:** none (verification and PR only)

- [ ] **Step 1: Run the full test suite**

Run: `xcodebuild -project Lumi.xcodeproj -scheme Lumi -configuration Debug test -only-testing:LumiTests CODE_SIGNING_ALLOWED=NO`
Expected: PASS — all prior 61 tests plus the ~20 new tests from Tasks 2–5, no regressions.

- [ ] **Step 2: Run the full lint suite**

Run: `swiftlint lint --strict Lumi`
Expected: no violations.

- [ ] **Step 3: Push the branch**

```bash
git push -u origin feat/inventory-builder
```

- [ ] **Step 4: Open the PR**

Replace `<N>` with the issue number from Task 1.

```bash
gh pr create \
  --title "feat: add inventory builder correlation layer" \
  --body "$(cat <<'EOF'
## Summary
Implements docs/superpowers/specs/2026-08-08-inventory-builder-design.md: a `SkillFrontmatter`
parser, `Marketplace.discoveredURLs`, `SkillOriginResolver` (plugin/repo-install/hand-written,
path-containment not string-prefix), and `SkillInventoryBuilder` orchestrating them plus stage 5's
plugin catalog drift detector and a new installed-vs-enabled check. Global skills only.

## Test plan
- `xcodebuild ... test -only-testing:LumiTests` — full suite green
- `swiftlint lint --strict Lumi` — clean
EOF
)" \
  --label enhancement \
  --assignee "@me" \
  --milestone "V1"
```

Add `Closes #<N>` to the body before creating, or edit the PR after creation to reference the
Task 1 issue.

- [ ] **Step 5: Watch CI**

```bash
gh pr checks --watch
```

Expected: all checks pass. If `build-and-test` fails on something that passed locally, investigate
before merging — the CI runner uses a different ICU/OS version than this dev machine (see the
handoff's ICU collation note), so a real divergence here would be a first.
