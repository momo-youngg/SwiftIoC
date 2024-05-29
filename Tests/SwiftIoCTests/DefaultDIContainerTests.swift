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
    
    @Component
    public class SingleDependencyClass {
        @Autowired
        var dependency: NoDependencyClass
    }

    func test_DIContainer_returns_proper_instance() {
        let sut: DIContainer = DIContainer.shared
        
        let actual: Componentable = sut.resolve(NoDependencyClass.self)
        
        XCTAssertTrue(actual is NoDependencyClass)
    }
    
    func test_DIContainer_works_having_dependency_class() {
        let sut: DIContainer = DIContainer.shared
        
        let actual: Componentable = sut.resolve(SingleDependencyClass.self)
        
        XCTAssert(actual is SingleDependencyClass)
        XCTAssert((actual as? SingleDependencyClass)?.dependency is NoDependencyClass)
    }
}
