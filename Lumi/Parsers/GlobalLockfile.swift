//
//  GlobalLockfile.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

struct GlobalLockfile: Decodable, Equatable {
    let version: Int
    let skills: [String: GlobalLockfileEntry]
    let dismissed: [String]
    let lastSelectedAgents: [String]

    static func decode(from data: Data) throws -> GlobalLockfile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .lumiISO8601
        return try decoder.decode(GlobalLockfile.self, from: data)
    }

    static func defaultURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL {
        if let xdgStateHome = environment["XDG_STATE_HOME"], !xdgStateHome.isEmpty {
            return URL(fileURLWithPath: xdgStateHome)
                .appendingPathComponent("skills")
                .appendingPathComponent(".skill-lock.json")
        }
        return URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".agents")
            .appendingPathComponent(".skill-lock.json")
    }
}

struct GlobalLockfileEntry: Decodable, Equatable {
    let source: String
    let sourceType: String
    let sourceUrl: String?
    let skillPath: String
    let skillFolderHash: String
    let pluginName: String?
    let installedAt: Date
    let updatedAt: Date
}
