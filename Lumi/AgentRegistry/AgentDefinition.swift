//
//  AgentDefinition.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

struct AgentDefinition: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let globalBase: String
    let globalBaseEnvOverride: String?
    let globalSkillsSubpath: String
    let projectSkillsDir: String?

    func globalSkillsURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        let override = globalBaseEnvOverride
            .flatMap { environment[$0] }
            .flatMap { $0.isEmpty ? nil : $0 }
        let base = (override ?? globalBase).expandingTildeInPath
        return URL(fileURLWithPath: base).appendingPathComponent(globalSkillsSubpath)
    }
}

private extension String {
    var expandingTildeInPath: String {
        (self as NSString).expandingTildeInPath
    }
}
