//
//  QualifierMacroTests.swift
//  
//
//  Created by momo on 6/1/24.
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

final class QualifierMacroTests: XCTestCase {

    #if canImport(SwiftIoCMacros)
    let testMacros: [String: Macro.Type] = [
        "Qualifier": QualifierMacro.self,
    ]
    #endif
    
    func test_qualifier_macro_attached_on_property_does_nothing() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            final class TestClass {
                @Qualifier
                private let myProperty = 1
            
                init() { }
            }
            """#,
            expandedSource: #"""
            final class TestClass {
                private let myProperty = 1
            
                init() { }
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
