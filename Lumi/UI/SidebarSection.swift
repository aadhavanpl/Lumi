//
//  SidebarSection.swift
//  Lumi
//
//  Created by Aadhavan on 09/08/26.
//

import Foundation

enum SidebarSection: Hashable {
    case allSkills
    case byScope(SkillScope)
    case byAgent(String)
    case plugins
    case needsAttention
}
