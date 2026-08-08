//
//  SkillScanner.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

enum SkillScanner {
    static let skipDirectoryNames: Set<String> = ["node_modules", ".git", "dist", "build", "__pycache__"]

    static func findSkillDirectories(under root: URL, fileManager: FileManager = .default) -> [URL] {
        var found: [URL] = []
        walk(root, fileManager: fileManager, into: &found)
        return dedupe(found)
    }

    /// Resolves symlinks before listing: asking `contentsOfDirectory` to list a symlink's
    /// contents directly fails with ENOTDIR, so every directory is canonicalized first.
    private static func walk(_ directory: URL, fileManager: FileManager, into found: inout [URL]) {
        let resolvedDirectory = directory.resolvingSymlinksInPath()

        guard let entries = try? fileManager.contentsOfDirectory(
            at: resolvedDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else {
            return
        }

        guard !entries.contains(where: { $0.lastPathComponent == "SKILL.md" }) else {
            found.append(resolvedDirectory)
            return
        }

        for entry in entries {
            guard !skipDirectoryNames.contains(entry.lastPathComponent) else { continue }
            guard (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { continue }
            walk(entry, fileManager: fileManager, into: &found)
        }
    }

    private static func dedupe(_ urls: [URL]) -> [URL] {
        var seenPaths: Set<String> = []
        return urls.filter { seenPaths.insert($0.path).inserted }
    }

    static func scanGlobalSkills(
        registry: [AgentDefinition],
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> [DiscoveredSkill] {
        registry.flatMap { agent in
            findSkillDirectories(under: agent.globalSkillsURL(environment: environment), fileManager: fileManager)
                .map { DiscoveredSkill(path: $0, agentID: agent.id, scope: .global) }
        }
    }

    static func scanProjectSkills(
        registry: [AgentDefinition],
        projectRoots: [URL],
        fileManager: FileManager = .default
    ) -> [DiscoveredSkill] {
        let agentsWithProjectScope = registry.compactMap { agent in
            agent.projectSkillsDir.map { (agent, $0) }
        }

        return projectRoots.flatMap { root in
            agentsWithProjectScope.flatMap { agent, projectSkillsDir in
                findSkillDirectories(under: root.appendingPathComponent(projectSkillsDir), fileManager: fileManager)
                    .map { DiscoveredSkill(path: $0, agentID: agent.id, scope: .project(root: root)) }
            }
        }
    }
}
