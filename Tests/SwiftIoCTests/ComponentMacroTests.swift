//
//  ComponentMacroTests.swift
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

final class ComponentMacroTests: XCTestCase {
    
    #if canImport(SwiftIoCMacros)
    let testMacros: [String: Macro.Type] = [
        "Component": ComponentMacro.self,
    ]
    #endif

    func test_component_macro_attached_on_property_does_nothing() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            final class TestClass {
                @Component
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
    
    func test_component_macro_attached_on_empty_property_type_generates_empty_initiaizer_and_protocol_conformance() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            @Component
            public final class TestClass {
            }
            """#,
            expandedSource: #"""
            public final class TestClass {
            
                public init() {
                }
            }
            
            extension TestClass: Componentable {
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_component_macro_attached_on_non_final_empty_property_class_generates_required_empty_initiaizer_and_protocol_conformance() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            @Component
            public class TestClass {
            }
            """#,
            expandedSource: #"""
            public class TestClass {
            
                required public init() {
                }
            }
            
            extension TestClass: Componentable {
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_component_macro_attached_on_empty_property_struct_generates_empty_initiaizer_and_protocol_conformance() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            @Component
            public struct TestStruct {
            }
            """#,
            expandedSource: #"""
            public struct TestStruct {
            
                public init() {
                }
            }
            
            extension TestStruct: Componentable {
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_component_macro_attached_on_type_with_empty_initializer_generates_protocol_conformance_only() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            @Component
            final public class TestClass {
            
                public init() {
                }
            }
            """#,
            expandedSource: #"""
            final public class TestClass {
            
                public init() {
                }
            }
            
            extension TestClass: Componentable {
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_component_macro_attached_on_type_with_final_empty_initializer_generates_protocol_conformance_only() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            @Component
            final public class TestClass {
            
                public final init() {
                }
            }
            """#,
            expandedSource: #"""
            final public class TestClass {
            
                public final init() {
                }
            }
            
            extension TestClass: Componentable {
            }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_component_macro_attached_on_type_with_empty_initializer_which_is_not_public_makes_error_diagnostic() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            @Component
            public final class TestClass {
            
                init() {
                }
            }
            """#,
            expandedSource: #"""
            public final class TestClass {
            
                init() {
                }
            }
            
            extension TestClass: Componentable {
            }
            """#,
            diagnostics: [DiagnosticSpec(message: "When using the @Component macro, if you implement the init() initializer, it must be public.", line: 1, column: 1)],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_component_macro_attached_on_type_which_is_not_public_makes_error_diagnostic() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            @Component
            final class TestClass {
            }
            """#,
            expandedSource: #"""
            final class TestClass {
            }
            
            extension TestClass: Componentable {
            }
            """#,
            diagnostics: [DiagnosticSpec(message: "@Component must be attached on public modifier.", line: 1, column: 1)],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func test_component_macro_attached_on_enum_makes_error_diagnostic() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            @Component
            enum TestEnum {
            }
            """#,
            expandedSource: #"""
            enum TestEnum {
            }
            
            extension TestEnum: Componentable {
            }
            """#,
            diagnostics: [DiagnosticSpec(message: "@Component can attached on class or struct only.", line: 1, column: 1)],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_component_macro_attached_on_non_final_class_generates_required_initializer() {
        #if canImport(SwiftIoCMacros)
        assertMacroExpansion(
            #"""
            @Component
            public class TestClass {
            
                public init() {
                }
            }
            """#,
            expandedSource: #"""
            public class TestClass {
            
                public init() {
                }
            }
            
            extension TestClass: Componentable {
            }
            """#,
            diagnostics: [DiagnosticSpec(message: "When using the @Component macro, if you implement the init() initializer in a non-final class, it must be required.", line: 1, column: 1)],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
