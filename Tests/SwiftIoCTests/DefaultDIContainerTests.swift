//
//  DefaultDIContainerTests.swift
//  
//
//  Created by momo on 5/29/24.
//

import XCTest
import SwiftIoCMacros
import SwiftIoC

final class DefaultDIContainerTests: XCTestCase {
    @Component
    public class NoDependencyClass {
        let normalProperty: Int = 1
    }

    func test_DIContainer_returns_proper_instance() {
        let sut: DIContainer = DIContainer.shared
        
        let actual: Componentable = sut.resolve(NoDependencyClass.self)
        
        XCTAssertTrue(actual is NoDependencyClass)
    }
}
