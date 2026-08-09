//
//  SkillStatus+Description.swift
//  Lumi
//
//  Created by Aadhavan on 09/08/26.
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
