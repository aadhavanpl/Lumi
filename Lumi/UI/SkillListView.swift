//
//  SkillListView.swift
//  Lumi
//

import SwiftUI

struct SkillListView: View {
    let items: [SkillInventoryItem]
    @Binding var selection: String?

    private let columnWidths = ColumnWidths()

    private var rows: [GroupedSkillRow] {
        InventoryFiltering.groupedRows(from: items)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            List(rows, selection: $selection) { row in
                SkillRow(row: row, columnWidths: columnWidths)
                    .tag(row.primaryItem.id)
            }
            .listStyle(.inset)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("Name").frame(maxWidth: .infinity, alignment: .leading)
            Text("Origin").frame(width: columnWidths.origin, alignment: .leading)
            Text("Scope").frame(width: columnWidths.scope, alignment: .leading)
            Text("Agent").frame(width: columnWidths.agent, alignment: .leading)
            Text("Version").frame(width: columnWidths.version, alignment: .leading)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

struct ColumnWidths {
    let origin: CGFloat = 110
    let scope: CGFloat = 70
    let agent: CGFloat = 76
    let version: CGFloat = 70
}

private struct SkillRow: View {
    let row: GroupedSkillRow
    let columnWidths: ColumnWidths

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if !row.statuses.isEmpty {
                        Circle().fill(.red).frame(width: 6, height: 6)
                    }
                    Text(row.name).fontWeight(.semibold)
                }
                if let description = row.description {
                    Text(description).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            OriginChip(origin: row.origin)
                .frame(width: columnWidths.origin, alignment: .leading)

            Text(row.scope.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: columnWidths.scope, alignment: .leading)

            AgentAvatarStack(agentIDs: row.agentIDs)
                .frame(width: columnWidths.agent, alignment: .leading)

            Text(versionLabel(row.origin))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: columnWidths.version, alignment: .leading)
        }
        .padding(.vertical, 4)
    }

    private func versionLabel(_ origin: SkillOrigin) -> String {
        if case .plugin(_, _, let version) = origin { return "v\(version)" }
        return "—"
    }
}

private struct OriginChip: View {
    let origin: SkillOrigin

    var body: some View {
        Text(label)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        switch origin {
        case .plugin: return "Plugin"
        case .repoInstall: return "Repo install"
        case .handWritten: return "Hand-written"
        }
    }

    private var color: Color {
        switch origin {
        case .plugin: return .blue
        case .repoInstall: return .orange
        case .handWritten: return .green
        }
    }
}

/// Overlapping circular logos, one per agent the skill is installed for. A single agent
/// renders with no overlap; each additional avatar stacks partially behind the previous one.
private struct AgentAvatarStack: View {
    let agentIDs: [String]

    private let overlap: CGFloat = 8

    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(agentIDs.enumerated()), id: \.offset) { index, agentID in
                AgentIconView(agentID: agentID)
                    .zIndex(Double(agentIDs.count - index))
            }
        }
    }
}

private struct AgentIconView: View {
    let agentID: String

    private let diameter: CGFloat = 20

    var body: some View {
        Group {
            if let image = NSImage(named: AgentIcon.assetName(forAgentID: agentID)) {
                Image(nsImage: image).resizable().scaledToFit()
            } else {
                Text(agentID.prefix(2).uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .background(.secondary.opacity(0.15))
            }
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.background, lineWidth: 1.5))
        .help(agentID)
    }
}

#Preview {
    SkillListView(items: [], selection: .constant(nil))
}
