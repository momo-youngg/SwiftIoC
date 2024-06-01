import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

@main
struct SwiftIoCPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutowiredMacro.self,
        ComponentMacro.self,
        QualifierMacro.self,
        QualifiedMacro.self,
    ]
}
