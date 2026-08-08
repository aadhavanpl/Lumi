//
//  LocalDriftDetector.swift
//  Lumi
//
//  Created by Aadhavan on 08/08/26.
//

import Foundation

/// Only `ProjectLockfileEntry.computedHash` (64-hex SHA-256) is comparable to a locally
/// recomputed hash — the global lock's `skillFolderHash` is a git tree SHA (RESEARCH §2).
enum LocalDriftDetector {
    static func hasDrifted(computedHash: String, entry: ProjectLockfileEntry) -> Bool {
        computedHash != entry.computedHash
    }
}
