//
//  SkillStatus+Description.swift
//  Lumi
//

import Foundation

extension SkillStatus {
    var detailDescription: String {
        switch self {
        case .pluginCatalogDrifted(let installedSha, let pinnedSha):
            return "Installed version \(installedSha) differs from marketplace catalog \(pinnedSha)."
        case .installedButDisabled:
            return "Installed but not enabled in settings.json."
        }
    }
}
