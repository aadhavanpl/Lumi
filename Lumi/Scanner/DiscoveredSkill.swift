//
//  DiscoveredSkill.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

enum SkillScope: Equatable {
    case global
    case project(root: URL)
}

struct DiscoveredSkill: Equatable {
    let path: URL
    let agentID: String
    let scope: SkillScope
}
