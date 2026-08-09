//
//  SkillStatusDescriptionTests.swift
//  LumiTests
//
//  Created by Aadhavan on 09/08/26.
//

import Foundation
@testable import Lumi
import Testing

struct SkillStatusDescriptionTests {

    @Test func pluginCatalogDriftedDescribesBothShasWithoutAccusingTheUser() {
        let status = SkillStatus.pluginCatalogDrifted(installedSha: "abc123", pinnedSha: "def456")
        #expect(status.detailDescription == "Installed version abc123 differs from marketplace catalog def456.")
    }

    @Test func installedButDisabledDescribesSettingsState() {
        let status = SkillStatus.installedButDisabled
        #expect(status.detailDescription == "Installed but not enabled in settings.json.")
    }
}
