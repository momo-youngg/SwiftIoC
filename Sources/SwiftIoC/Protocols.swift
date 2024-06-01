//
//  File.swift
//  
//
//  Created by momo on 6/2/24.
//

import Foundation

@objc public protocol Componentable {
    init()
}

public protocol DependencyResolvable {
    func resolve<T: Componentable>(_ type: T.Type, qualifier: String?) -> T
}

public protocol Qualifiable {
    var _qualifier: String { get }
}
