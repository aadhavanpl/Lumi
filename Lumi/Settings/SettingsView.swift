//
//  SettingsView.swift
//  Lumi
//
//  Created by Aadhavan on 14/08/26.
//

import SwiftUI

struct SettingsView: View {
    @State private var workspaces: [URL] = []

    var body: some View {
        Form {
            Section {
                if workspaces.isEmpty {
                    Text("No folders registered yet. Add a folder to scan for project-scoped skills.")
                } else {
                    ForEach(workspaces, id: \.self) { workspace in
                        HStack {
                            Text(workspace.path)
                                .textSelection(.enabled)
                            Spacer()
                            Button("Remove") { remove(workspace) }
                        }
                    }
                }
                HStack {
                    Button("Add Folder…") { addWorkspace() }
                    Spacer()
                }
            } header: {
                Text("Workspaces")
            } footer: {
                Text("Registered folders are picked up on the next Refresh.")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 440, minHeight: 220)
        .onAppear { workspaces = WorkspaceStore.load() }
    }

    private func addWorkspace() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Add Folder"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let updated = WorkspaceStore.addIfValid(url, to: workspaces) else { return }
        workspaces = updated
        try? WorkspaceStore.save(workspaces)
    }

    private func remove(_ workspace: URL) {
        workspaces = WorkspaceStore.remove(workspace, from: workspaces)
        try? WorkspaceStore.save(workspaces)
    }
}

#Preview {
    SettingsView()
}
