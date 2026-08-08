//
//  SkillFolderHasher.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import CryptoKit
import Foundation

enum SkillFolderHasher {
    static let skipDirectoryNames: Set<String> = [".git", "node_modules"]

    /// Case-insensitive sort, not `<`, to match JS `String.localeCompare` (RESEARCH-skills-sh.md §3).
    static func computeHash(at root: URL, fileManager: FileManager = .default) throws -> String {
        let resolvedRoot = root.resolvingSymlinksInPath()
        let relativePaths = try collectRelativeFilePaths(under: resolvedRoot, fileManager: fileManager)
            .sorted { $0.compare($1, options: .caseInsensitive) == .orderedAscending }

        var hasher = SHA256()
        for relativePath in relativePaths {
            hasher.update(data: Data(relativePath.utf8))
            let fileData = try Data(contentsOf: resolvedRoot.appendingPathComponent(relativePath))
            hasher.update(data: fileData)
        }
        return hasher.finalize().compactMap { String(format: "%02x", $0) }.joined()
    }

    private static func collectRelativeFilePaths(
        under directory: URL,
        relativePrefix: String = "",
        fileManager: FileManager
    ) throws -> [String] {
        let resolvedDirectory = directory.resolvingSymlinksInPath()
        let entries = try fileManager.contentsOfDirectory(
            at: resolvedDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        )

        var results: [String] = []
        for entry in entries {
            guard !skipDirectoryNames.contains(entry.lastPathComponent) else { continue }
            let relativePath = relativePrefix.isEmpty
                ? entry.lastPathComponent
                : "\(relativePrefix)/\(entry.lastPathComponent)"

            if (try entry.resourceValues(forKeys: [.isDirectoryKey])).isDirectory == true {
                results += try collectRelativeFilePaths(
                    under: entry,
                    relativePrefix: relativePath,
                    fileManager: fileManager
                )
            } else {
                results.append(relativePath)
            }
        }
        return results
    }
}
