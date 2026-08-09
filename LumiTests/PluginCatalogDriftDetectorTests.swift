//
//  PluginCatalogDriftDetectorTests.swift
//  LumiTests
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct PluginCatalogDriftDetectorTests {

    private func installedEntry(gitCommitSha: String?) -> InstalledPluginEntry {
        InstalledPluginEntry(
            scope: "user",
            projectPath: nil,
            installPath: "/Users/aadhavan/.claude/plugins/cache/claude-plugins-official/superpowers/6.0.3",
            version: "6.0.3",
            installedAt: Date(),
            lastUpdated: Date(),
            gitCommitSha: gitCommitSha
        )
    }

    private func marketplace(pluginSource: MarketplacePluginSource) -> Marketplace {
        Marketplace(
            name: "claude-plugins-official",
            plugins: [MarketplacePlugin(name: "superpowers", category: "development", source: pluginSource)]
        )
    }

    private func pinnedSource(sha: String) -> MarketplacePluginSource {
        .pinned(PinnedMarketplaceSource(
            kind: "url",
            url: "https://github.com/obra/superpowers.git",
            path: nil,
            ref: nil,
            sha: sha
        ))
    }

    // Real values from this machine's reference data, matching ADR 0007's example.
    @Test func reportsDriftedWhenInstalledShaDiffersFromPinnedSha() {
        let status = PluginCatalogDriftDetector.detect(
            pluginName: "superpowers",
            installed: installedEntry(gitCommitSha: "6fd4507659784c351abbd2bc264c7162cfd386dc"),
            marketplace: marketplace(pluginSource: pinnedSource(sha: "896224c4b1879920ab573417e68fd51d2ccc9072"))
        )
        #expect(status == .drifted(
            installedSha: "6fd4507659784c351abbd2bc264c7162cfd386dc",
            pinnedSha: "896224c4b1879920ab573417e68fd51d2ccc9072"
        ))
    }

    @Test func reportsUpToDateWhenShasMatch() {
        let status = PluginCatalogDriftDetector.detect(
            pluginName: "superpowers",
            installed: installedEntry(gitCommitSha: "896224c4b1879920ab573417e68fd51d2ccc9072"),
            marketplace: marketplace(pluginSource: pinnedSource(sha: "896224c4b1879920ab573417e68fd51d2ccc9072"))
        )
        #expect(status == .upToDate)
    }

    @Test func reportsUnknownWhenPluginNotInMarketplace() {
        let status = PluginCatalogDriftDetector.detect(
            pluginName: "not-in-catalog",
            installed: installedEntry(gitCommitSha: "6fd4507659784c351abbd2bc264c7162cfd386dc"),
            marketplace: marketplace(pluginSource: pinnedSource(sha: "896224c4b1879920ab573417e68fd51d2ccc9072"))
        )
        #expect(status == .unknown)
    }

    @Test func reportsUnknownWhenMarketplaceSourceIsLocalWithNoPinnedSha() {
        let status = PluginCatalogDriftDetector.detect(
            pluginName: "superpowers",
            installed: installedEntry(gitCommitSha: "6fd4507659784c351abbd2bc264c7162cfd386dc"),
            marketplace: marketplace(pluginSource: .local(path: "./plugins/superpowers"))
        )
        #expect(status == .unknown)
    }

    @Test func reportsUnknownWhenInstalledEntryHasNoGitCommitSha() {
        let status = PluginCatalogDriftDetector.detect(
            pluginName: "superpowers",
            installed: installedEntry(gitCommitSha: nil),
            marketplace: marketplace(pluginSource: pinnedSource(sha: "896224c4b1879920ab573417e68fd51d2ccc9072"))
        )
        #expect(status == .unknown)
    }
}
