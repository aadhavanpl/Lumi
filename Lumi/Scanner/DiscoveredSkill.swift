//
//  DiscoveredSkill.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

enum SkillScope: Hashable {
    case global
    case project(root: URL)
}

extension SkillScope {
    var displayName: String {
        switch self {
        case .global: return "Global"
        case .project(let root): return root.lastPathComponent
        }
    }
}

struct DiscoveredSkill: Equatable {
    let path: URL
    let agentID: String
    let scope: SkillScope
}
