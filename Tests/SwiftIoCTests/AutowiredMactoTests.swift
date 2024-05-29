//
//  AutowiredMactoTests.swift
//  
//
//  Created by momo on 5/29/24.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(SwiftIoCMacros)
import SwiftIoCMacros
#endif

final class AutowiredMactoTests: XCTestCase {
    
    #if canImport(SwiftIoCMacros)
    let testMacros: [String: Macro.Type] = [
        "Autowired": AutowiredMacro.self,
    ]
    #endif
    
    func test_autowired_macro_attached_on_type_does_nothing() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            @Autowired
            final class TestClass {
            }
            """#,
            expandedSource: #"""
            final class TestClass {
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_autowired_macro_attached_on_let_property_generates_diagnostic() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            public final class TestClass {
                @Autowired
                private let someType: Int
            
                public init() {
                    self.someType = 1
                }
            }
            """#,
            expandedSource: #"""
            public final class TestClass {
                private let someType: Int
            
                private let _someType: Int = DIContainer.shared.resolve(Int.self)
            
                public init() {
                    self.someType = 1
                }
            }
            """#,
            diagnostics: [DiagnosticSpec(message: "The property with @Autowired must be variable.", line: 2, column: 5)],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_autowired_macro_attached_on_property_which_is_initialized_generates_diagnostic() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            public final class TestClass {
                @Autowired
                private var someType: Int = 1
            
                public init() {
                }
            }
            """#,
            expandedSource: #"""
            public final class TestClass {
                private var someType: Int = 1
            
                private let _someType: Int = DIContainer.shared.resolve(Int.self)
            
                public init() {
                }
            }
            """#,
            diagnostics: [DiagnosticSpec(message: "The property with @Autowired must not be initialized", line: 2, column: 5)],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_autowired_macro_attached_on_property_which_is_computed_property_generates_diagnostic() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            public final class TestClass {
                @Autowired
                private var someType: Int {
                    get {
                        return 1
                    }
                }
            }
            """#,
            expandedSource: #"""
            public final class TestClass {
                private var someType: Int {
                    get {
                        return 1
                    }
                }
            
                private let _someType: Int = DIContainer.shared.resolve(Int.self)
            }
            """#,
            diagnostics: [DiagnosticSpec(message: "The property with @Autowired must stored property.", line: 2, column: 5)],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_autowired_macro_generates_peer_property_and_get_accessor() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            public final class TestClass {
                @Autowired(container: DefaultDIContainer.shared)
                private var someType: Int
            
                public init() { }
            }
            """#,
            expandedSource: #"""
            public final class TestClass {
                private var someType: Int {
                    get {
                        self._someType
                    }
                }
            
                private let _someType: Int = DefaultDIContainer.shared.resolve(Int.self)
            
                public init() { }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_autowired_macro_with_no_argument_generates_peer_property_and_get_accessor() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            public final class TestClass {
                @Autowired
                private var someType: Int
            
                public init() { }
            }
            """#,
            expandedSource: #"""
            public final class TestClass {
                private var someType: Int {
                    get {
                        self._someType
                    }
                }
            
                private let _someType: Int = DIContainer.shared.resolve(Int.self)
            
                public init() { }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

}
