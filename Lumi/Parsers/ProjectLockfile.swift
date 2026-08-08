//
//  ProjectLockfile.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

struct ProjectLockfile: Decodable, Equatable {
    let version: Int
    let skills: [String: ProjectLockfileEntry]

    static func decode(from data: Data) throws -> ProjectLockfile {
        try JSONDecoder().decode(ProjectLockfile.self, from: data)
    }

    static func url(forProjectRoot root: URL) -> URL {
        root.appendingPathComponent("skills-lock.json")
    }
}

struct ProjectLockfileEntry: Decodable, Equatable {
    let source: String
    let sourceType: String
    let skillPath: String
    let computedHash: String
}
