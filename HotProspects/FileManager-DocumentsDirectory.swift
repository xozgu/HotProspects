//
//  FileManager-DocumentsDirectory.swift
//  BucketList
//
//  Created by Ozgu Ozden on 2022/05/09.
//

import Foundation

extension FileManager {
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
