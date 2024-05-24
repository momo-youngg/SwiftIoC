import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

@main
struct SwiftIoCPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        ComponentMacro.self,
    ]
}

public struct ComponentMacro: AccessorMacro {
    enum ComponentDiagnostic: DiagnosticMessage {
        case notProperty

        public var message: String {
            switch self {
            case .notProperty:
                return "@Component must be attached to constant stored property"
            }
        }
        
        public var diagnosticID: SwiftDiagnostics.MessageID {
            MessageID(domain: String(describing: self), id: String(describing: self))
        }
        
        public var severity: SwiftDiagnostics.DiagnosticSeverity {
            switch self {
            case .notProperty:
                return .error
            }
        }
    }
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
                varDecl.bindingSpecifier.tokenKind == .keyword(.let) else {
            context.diagnose(Diagnostic(node: node, message: ComponentDiagnostic.notProperty))
            return []
        }
        return []
    }
}
