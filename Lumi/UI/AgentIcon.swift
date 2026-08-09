//
//  AgentIcon.swift
//  Lumi
//
//  Created by Aadhavan on 09/08/26.
//

import Foundation
import SwiftUI

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

    /// Matches each agent's own brand casing (e.g. "opencode" is lowercase by design).
    static func displayName(forAgentID agentID: String) -> String {
        switch agentID {
        case "claude-code": return "Claude Code"
        case "codex": return "Codex"
        case "cursor": return "Cursor"
        case "opencode": return "opencode"
        case "github-copilot": return "GitHub Copilot"
        default: return agentID
        }
    }

    /// Backdrop color for the circular badge, since source logos vary between a colored
    /// background, a white background, and no background at all — a consistent brand-colored
    /// circle keeps every agent's badge legible against the list's white row background.
    static func brandColor(forAgentID agentID: String) -> Color {
        switch agentID {
        case "claude-code": return Color(red: 0.843, green: 0.463, blue: 0.333)
        case "codex": return Color(red: 0.475, green: 0.541, blue: 1.0)
        case "cursor": return .black
        case "opencode": return Color(red: 0.294, green: 0.275, blue: 0.275)
        case "github-copilot": return Color(white: 0.93)
        default: return .secondary
        }
    }
}
