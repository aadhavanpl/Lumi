//
//  SkillFrontmatter.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

struct SkillFrontmatter: Equatable {
    let name: String?
    let description: String?

    static func parse(contentsOf skillMDPath: URL, fileManager: FileManager = .default) -> SkillFrontmatter {
        guard let data = fileManager.contents(atPath: skillMDPath.path),
              let contents = String(data: data, encoding: .utf8) else {
            return SkillFrontmatter(name: nil, description: nil)
        }
        return parse(contents)
    }

    private static func parse(_ contents: String) -> SkillFrontmatter {
        let lines = contents.components(separatedBy: .newlines)
        guard lines.first == "---",
              let closingIndex = lines.dropFirst().firstIndex(of: "---") else {
            return SkillFrontmatter(name: nil, description: nil)
        }

        var name: String?
        var description: String?
        for line in lines[1..<closingIndex] {
            guard let colonIndex = line.firstIndex(of: ":") else { continue }
            let key = line[line.startIndex..<colonIndex].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
            guard !value.isEmpty else { continue }

            switch key {
            case "name": name = value
            case "description": description = value
            default: break
            }
        }
        return SkillFrontmatter(name: name, description: description)
    }
}
