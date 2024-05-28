import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

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
        AutowiredMacro.self,
        ComponentMacro.self,
    ]
}

public struct AutowiredMacro: AccessorMacro {
    enum AutowiredDiagnostic: DiagnosticMessage {
        case notProperty

        public var message: String {
            switch self {
            case .notProperty:
                return "@Autowired must be attached to constant stored property"
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
            context.diagnose(Diagnostic(node: node, message: AutowiredDiagnostic.notProperty))
            return []
        }
        return []
    }
}

public struct ComponentMacro: MemberMacro, ExtensionMacro {
    enum ComponentDiagnostic: DiagnosticMessage {
        case notPublicInit
        case notPublicType

        public var message: String {
            switch self {
            case .notPublicInit:
                return "The manually implemented parameterless initializer must be public."
            case .notPublicType:
                return "@Component must be attached on public modifier."
            }
        }
        
        public var diagnosticID: SwiftDiagnostics.MessageID {
            MessageID(domain: String(describing: self), id: String(describing: self))
        }
        
        public var severity: SwiftDiagnostics.DiagnosticSeverity {
            switch self {
            case .notPublicInit, .notPublicType:
                return .error
            }
        }
    }

    public static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let typeModifiers = declaration.modifiers.as(DeclModifierListSyntax.self) else {
            return []
        }
        let publicTypeModifiers = typeModifiers.filter { $0.name.tokenKind == .keyword(.public) }
        guard publicTypeModifiers.isEmpty == false else {
            context.diagnose(Diagnostic(node: node, message: ComponentDiagnostic.notPublicType))
            return []
        }
        
        guard let memberBlock = declaration.memberBlock.as(MemberBlockSyntax.self),
              let memberList = memberBlock.members.as(MemberBlockItemListSyntax.self) else {
            return []
        }
        let members = memberList.compactMap { $0.as(MemberBlockItemSyntax.self) }
        let initializers = members.compactMap { $0.decl.as(InitializerDeclSyntax.self) }
        let emptyParameterInitializer = initializers
            .filter { initializerDeclaration in
                guard let signature = initializerDeclaration.signature.as(FunctionSignatureSyntax.self),
                      let parameterClause = signature.parameterClause.as(FunctionParameterClauseSyntax.self),
                      let paramters = parameterClause.parameters.as(FunctionParameterListSyntax.self) else {
                    return false
                }
                let isParamtersEmpty = paramters.count == .zero
                return isParamtersEmpty
            }
        
        guard emptyParameterInitializer.isEmpty == false else {
            let initializer = Self.initializer()
            return [initializer]
        }
        
        let publicEmptyParameterInitializer = emptyParameterInitializer.filter { initializerDeclaration in
            guard let modifiers = initializerDeclaration.modifiers.as(DeclModifierListSyntax.self) else {
                return false
            }
            let publicModifiers = modifiers
                .compactMap { $0.as(DeclModifierSyntax.self) }
                .filter { 
                    return $0.name.tokenKind == .keyword(.public)
                }
            return publicModifiers.isEmpty == false
        }
        
        guard publicEmptyParameterInitializer.isEmpty == false else {
            context.diagnose(Diagnostic(node: node, message: ComponentDiagnostic.notPublicInit))
            return []
        }
        
        return []
    }
    
    private static func initializer() -> DeclSyntax {
        return """
        public init() {
        }
        """
    }
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let extensionDeclSyntax = conformance(providingExtensionsOf: type).as(ExtensionDeclSyntax.self) else {
            return []
        }
        return [extensionDeclSyntax]
    }

    private static func conformance(providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol) -> DeclSyntax {
        return """
        extension \(type.trimmed): Componentable {
        }
        """
    }
}
