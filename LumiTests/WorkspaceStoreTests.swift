//
//  WorkspaceStoreTests.swift
//  LumiTests
//
//  Created by Aadhavan on 14/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct WorkspaceStoreTests {

    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func withTempFile(_ body: (URL) throws -> Void) rethrows {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        try body(url)
    }

    @Test func loadReturnsEmptyWhenFileDoesNotExist() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")

        let workspaces = WorkspaceStore.load(url: url)

        #expect(workspaces.isEmpty)
    }

    @Test func loadReturnsEmptyWhenFileIsMalformed() {
        withTempFile { url in
            try? "{ not valid json".write(to: url, atomically: true, encoding: .utf8)

            let workspaces = WorkspaceStore.load(url: url)

            #expect(workspaces.isEmpty)
        }
    }

    @Test func saveAndLoadRoundTripsStoredPaths() throws {
        try withTempFile { url in
            let workspace = makeTempDirectory()
            defer { try? FileManager.default.removeItem(at: workspace) }
            let workspaces = [workspace]

            try WorkspaceStore.save(workspaces, to: url)
            let loaded = WorkspaceStore.load(url: url)

            #expect(loaded == [workspace])
        }
    }

    @Test func addRejectsAPathThatIsNotADirectory() {
        let file = makeTempDirectory().appendingPathComponent("not-a-dir")
        try? Data().write(to: file)

        let result = WorkspaceStore.addIfValid(file, to: [])

        #expect(result == nil)
    }

    @Test func addRejectsAnExistingDirectory() {
        let workspace = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }

        let result = WorkspaceStore.addIfValid(workspace, to: [workspace])

        #expect(result == nil)
    }

    @Test func addStoresTheResolvedSymlinkTarget() throws {
        let real = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: real) }
        let link = real.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: link) }
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)

        let result = WorkspaceStore.addIfValid(link, to: [])

        let added = try #require(result)
        #expect(added == [real])
    }

    @Test func removeDropsTheMatchingResolvedPath() {
        let workspace = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }

        let result = WorkspaceStore.remove(workspace, from: [workspace])

        #expect(result.isEmpty)
    }
}
