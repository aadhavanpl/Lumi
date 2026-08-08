//
//  ShadowingDetector.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

struct ShadowedSkill: Equatable {
    let name: String
    let agentID: String
    let projectRoot: URL
    let shadowingPath: URL
    let shadowedPath: URL
}

/// ADR 0004: project scope shadows global, per (skill name, agent).
enum ShadowingDetector {
    static func detect(discovered: [DiscoveredSkill]) -> [ShadowedSkill] {
        let byAgent = Dictionary(grouping: discovered, by: \.agentID)

        return byAgent.flatMap { agentID, skills -> [ShadowedSkill] in
            let byName = Dictionary(grouping: skills, by: \.path.lastPathComponent)

            return byName.flatMap { name, group -> [ShadowedSkill] in
                guard let globalPath = group.first(where: { $0.scope == .global })?.path else { return [] }

                return group.compactMap { skill in
                    guard case .project(let root) = skill.scope else { return nil }
                    return ShadowedSkill(
                        name: name,
                        agentID: agentID,
                        projectRoot: root,
                        shadowingPath: skill.path,
                        shadowedPath: globalPath
                    )
                }
            }
        }
    }
}
