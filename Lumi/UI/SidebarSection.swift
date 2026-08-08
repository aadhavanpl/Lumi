//
//  SidebarSection.swift
//  Lumi
//

import Foundation

enum SidebarSection: Hashable {
    case allSkills
    case byScope(SkillScope)
    case byAgent(String)
    case plugins
    case needsAttention
}
