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
    
    func test_autowired_macro_does_not_add_any_accessors() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            final class TestClass {
                @Autowired
                private let myProperty: Int = 1
            }
            """#,
            expandedSource: #"""
            final class TestClass {
                private let myProperty: Int = 1
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_autowired_macro_can_use_with_other_property() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            final class TestClass {
                @Autowired
                private let myProperty: Int = 1
            
                private var otherProperty: Bool = false
            }
            """#,
            expandedSource: #"""
            final class TestClass {
                private let myProperty: Int = 1
            
                private var otherProperty: Bool = false
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_autowired_macro_can_use_in_type_which_has_initializer() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            final class TestClass {
                @Autowired
                private let myProperty: Int = 1
            
                private var otherProperty: Bool = false
            
                init() { }
            }
            """#,
            expandedSource: #"""
            final class TestClass {
                private let myProperty: Int = 1
            
                private var otherProperty: Bool = false
            
                init() { }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_autowired_macro_can_not_attach_on_computed_property() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            final class TestClass {
                @Autowired
                var myProperty: Int {
                    return 1
                }
            }
            """#,
            expandedSource: #"""
            final class TestClass {
                var myProperty: Int {
                    return 1
                }
            }
            """#,
            diagnostics: [DiagnosticSpec(message: "@Autowired must be attached to constant stored property", line: 2, column: 5)],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_autowired_macro_can_not_attach_on_variable_property() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            final class TestClass {
                @Autowired
                var myProperty: Int
            
                init() {
                    self.myProperty = 1
                }
            }
            """#,
            expandedSource: #"""
            final class TestClass {
                var myProperty: Int
            
                init() {
                    self.myProperty = 1
                }
            }
            """#,
            diagnostics: [DiagnosticSpec(message: "@Autowired must be attached to constant stored property", line: 2, column: 5)],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
