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
