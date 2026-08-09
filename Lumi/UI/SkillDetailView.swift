//
//  SkillDetailView.swift
//  Lumi
//
//  Created by Aadhavan on 09/08/26.
//

import SwiftUI

struct SkillDetailView: View {
    let item: SkillInventoryItem?

    var body: some View {
        if let item {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header(for: item)
                    originSection(for: item)
                    locationSection(for: item)
                    if !item.statuses.isEmpty {
                        statusSection(for: item)
                    }
                }
                .padding()
            }
        } else {
            ContentUnavailableView(
                "No Skill Selected",
                systemImage: "square.stack",
                description: Text("Select a skill from the list to see its details.")
            )
        }
    }

    private func header(for item: SkillInventoryItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name).font(.title2).fontWeight(.semibold)
            if let description = item.description {
                Text(description).foregroundStyle(.secondary)
            }
        }
    }

    private func originSection(for item: SkillInventoryItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Origin").font(.headline)
            switch item.origin {
            case .plugin(let name, let marketplaceName, let version):
                Text("Plugin: \(name) v\(version) from \(marketplaceName)")
            case .repoInstall(let source, let skillFolderHash):
                Text("Repo install: \(source)")
                Text("Skill folder hash: \(skillFolderHash)").font(.caption).foregroundStyle(.secondary)
            case .handWritten:
                Text("Hand-written")
            }
        }
    }

    private func locationSection(for item: SkillInventoryItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Location").font(.headline)
            Text(item.path.path).font(.system(.body, design: .monospaced)).textSelection(.enabled)
            Text("\(item.scope.displayName) · \(item.agentID)").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func statusSection(for item: SkillInventoryItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Status").font(.headline)
            ForEach(item.statuses, id: \.self) { status in
                Text(status.detailDescription)
            }
        }
    }
}

#Preview {
    SkillDetailView(item: nil)
}
