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
    
    @Component
    public class SingleDependencyClass2 {
        @Autowired
        var dependency: NoDependencyClass
    }

    protocol TestProtocol {
        var normalProperty: Int { get set }
    }
    
    @Component
    public class NoDependencyWithProtocolConformantClass: TestProtocol {
        var normalProperty: Int = 10
    }
    
    @Component
    public class SingleDependencyClass3 {
        @Autowired
        var dependency: TestProtocol
    }
    
    @Component
    public class SingleConcreteDependencyClass {
        @Autowired
        var  dependency: NoDependencyWithProtocolConformantClass
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
    
    func test_DIContainer_resolve_with_same_instance_() {
        let sut: DIContainer = DIContainer.shared
        
        let actual1 = sut.resolve(SingleDependencyClass.self)
        let actual2 = sut.resolve(SingleDependencyClass2.self)
        
        XCTAssert(actual1.dependency === actual2.dependency)
    }
    
    func test_DIContainer_resolve_works_with_protocol_type_property() {
        let sut: DIContainer = DIContainer.shared
        let expectedNormalProperty = Int.max
        var dependency = sut.resolve(TestProtocol.self)
        dependency.normalProperty = expectedNormalProperty
        
        let actual = sut.resolve(SingleDependencyClass3.self)
        
        XCTAssertEqual(actual.dependency.normalProperty, expectedNormalProperty)
    }
    
    func test_DIContainer_resolve_same_instance_with_protocol_and_concrete_class_type() {
        let sut: DIContainer = DIContainer.shared
        
        let concreteClassBased = sut.resolve(SingleConcreteDependencyClass.self)
        let protocolBased = sut.resolve(SingleDependencyClass3.self)
        
        if let dependency = protocolBased.dependency as? NoDependencyWithProtocolConformantClass {
            XCTAssertTrue(concreteClassBased.dependency === dependency)
        } else {
            XCTFail()
        }
    }
    
    func test_DIContainer_resolve_same_instance_with_protocol_and_concrete_class_type_with_thread_safe() {
        let iterateCount = 10000
        var expectations: [XCTestExpectation] = []
        
        (0..<iterateCount).forEach { _ in
            let exp = XCTestExpectation()
            expectations.append(exp)
            DispatchQueue.global().async {
                let sut: DIContainer = DIContainer.shared
                
                let concreteClassBased = sut.resolve(SingleConcreteDependencyClass.self)
                let protocolBased = sut.resolve(SingleDependencyClass3.self)
                
                if let dependency = protocolBased.dependency as? NoDependencyWithProtocolConformantClass {
                    XCTAssertTrue(concreteClassBased.dependency === dependency)
                    exp.fulfill()
                } else {
                    XCTFail()
                    exp.fulfill()
                }
            }
        }
        
        wait(for: expectations, timeout: 3.0)
    }
}
