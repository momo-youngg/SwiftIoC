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

}
