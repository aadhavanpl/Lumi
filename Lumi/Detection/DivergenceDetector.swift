//
//  DivergenceDetector.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

struct SkillCopy: Hashable {
    let path: URL
    let source: String
    let skillPath: String
    let contentHash: String
}

struct DivergentSkillGroup: Equatable {
    let source: String
    let skillPath: String
    let copies: [SkillCopy]
}

enum DivergenceDetector {
    private struct UpstreamIdentity: Hashable {
        let source: String
        let skillPath: String
    }

    static func detect(copies: [SkillCopy]) -> [DivergentSkillGroup] {
        let grouped = Dictionary(grouping: copies) { UpstreamIdentity(source: $0.source, skillPath: $0.skillPath) }

        return grouped.compactMap { identity, group in
            guard Set(group.map(\.path)).count > 1 else { return nil }
            guard Set(group.map(\.contentHash)).count > 1 else { return nil }
            return DivergentSkillGroup(source: identity.source, skillPath: identity.skillPath, copies: group)
        }
    }
}
