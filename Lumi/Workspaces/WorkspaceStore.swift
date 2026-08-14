//
//  WorkspaceStore.swift
//  Lumi
//
//  Created by Aadhavan on 14/08/26.
//

import Foundation

enum WorkspaceStore {
    static var userWorkspacesURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Lumi", isDirectory: true)
            .appendingPathComponent("workspaces.json")
    }

    static func load(url: URL = userWorkspacesURL) -> [URL] {
        guard let data = try? Data(contentsOf: url),
              let paths = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return paths.map { URL(fileURLWithPath: $0) }
    }

    static func save(_ workspaces: [URL], to url: URL = userWorkspacesURL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(workspaces.map(\.path))
        try data.write(to: url, options: .atomic)
    }

    /// Returns the workspaces with `folder` appended after resolving symlinks, or nil if it is
    /// not a directory or is already registered. User-supplied paths are untrusted (ADR 0014).
    static func addIfValid(_ folder: URL, to workspaces: [URL], fileManager: FileManager = .default) -> [URL]? {
        let resolved = folder.resolvingSymlinksInPath()
        guard (try? resolved.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { return nil }
        guard !workspaces.map { $0.resolvingSymlinksInPath().path }.contains(resolved.path) else { return nil }
        return workspaces + [resolved]
    }

    static func remove(_ folder: URL, from workspaces: [URL]) -> [URL] {
        let resolved = folder.resolvingSymlinksInPath()
        return workspaces.filter { $0.resolvingSymlinksInPath().path != resolved.path }
    }
}
