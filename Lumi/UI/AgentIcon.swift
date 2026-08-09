//
//  AgentIcon.swift
//  Lumi
//
//  Created by Aadhavan on 09/08/26.
//

import Foundation

/// Maps a known agent ID to an Assets.xcassets image set name. Real per-agent SVGs are dropped
/// into those named image sets separately — AgentIconView falls back gracefully if one is absent.
enum AgentIcon {
    static func assetName(forAgentID agentID: String) -> String {
        switch agentID {
        case "claude-code": return "AgentIcon-ClaudeCode"
        case "codex": return "AgentIcon-Codex"
        case "cursor": return "AgentIcon-Cursor"
        case "opencode": return "AgentIcon-OpenCode"
        case "github-copilot": return "AgentIcon-GitHubCopilot"
        default: return "AgentIcon-Unknown"
        }
    }
}
