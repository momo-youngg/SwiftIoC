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
        QualifierMacro.self,
    ]
}

public struct AutowiredMacro {
    enum AutowiredDiagnostic: DiagnosticMessage {
        case notVariableProperty
        case alreadyInitialized
        case storedProperty
        
        public var message: String {
            switch self {
            case .notVariableProperty:
                return "The property with @Autowired must be variable."
            case .alreadyInitialized:
                return "The property with @Autowired must not be initialized"
            case .storedProperty:
                return "The property with @Autowired must stored property."
            }
        }
        
        public var diagnosticID: SwiftDiagnostics.MessageID {
            MessageID(domain: String(describing: self), id: String(describing: self))
        }
        
        public var severity: SwiftDiagnostics.DiagnosticSeverity {
            switch self {
            case .notVariableProperty, .alreadyInitialized, .storedProperty:
                return .error
            }
        }
    }

}

extension AutowiredMacro: AccessorMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              varDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
            context.diagnose(Diagnostic(node: node, message: AutowiredDiagnostic.notVariableProperty))
            return []
        }
        if let bindings = varDecl.bindings.as(PatternBindingListSyntax.self) {
            let equalBinding = bindings.compactMap { $0.as(PatternBindingSyntax.self) }
                .filter { patternBindingSyntax in
                    if let initializer = patternBindingSyntax.initializer?.as(InitializerClauseSyntax.self), initializer.equal.tokenKind == .equal {
                        return true
                    } else {
                        return false
                    }
                }
            if equalBinding.isEmpty == false {
                context.diagnose(Diagnostic(node: node, message: AutowiredDiagnostic.alreadyInitialized))
                return []
            }
            
            let accessorBlock = bindings
                .compactMap { $0.as(PatternBindingSyntax.self) }
                .compactMap { $0.accessorBlock }
            if accessorBlock.isEmpty == false {
                context.diagnose(Diagnostic(node: node, message: AutowiredDiagnostic.storedProperty))
                return []
            }
            
            let containerArgument: String = {
                if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
                    if let containerArgument = arguments
                        .compactMap({ $0.as(LabeledExprSyntax.self) })
                        .filter({ $0.label?.text == "container" })
                        .compactMap({ $0.expression.as(MemberAccessExprSyntax.self) })
                        .map({ $0.description })
                        .first {
                        return containerArgument
                    }
                }
                return "DIContainer.shared"
            }()
            
            if let typeName = bindings
                .compactMap({ $0.as(PatternBindingSyntax.self) })
                .compactMap({ $0.typeAnnotation })
                .compactMap({ $0.as(TypeAnnotationSyntax.self) })
                .map({ $0.type })
                .compactMap({ $0.as(IdentifierTypeSyntax.self) })
                .map({ $0.name })
                .first {
                
                if let qualifier = varDecl
                    .attributes
                    .compactMap({ $0.as(AttributeSyntax.self) })
                    .filter({ $0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Qualifier" })
                    .compactMap({ $0.arguments })
                    .compactMap({ $0.as(LabeledExprListSyntax.self) })
                    .flatMap({ $0 })
                    .compactMap({ $0.as(LabeledExprSyntax.self) })
                    .compactMap({ $0.expression.as(StringLiteralExprSyntax.self) })
                    .flatMap({ $0.segments })
                    .compactMap({ $0.as(StringSegmentSyntax.self) })
                    .map({ $0.content.text }).first {
                    let newExpr = AccessorDeclSyntax(accessorSpecifier: .keyword(.get)) {
                        "\(raw: containerArgument).resolve(\(typeName.trimmed).self, qualifier: \"\(raw: qualifier)\")"
                    }
                    return [newExpr]
                } else {
                    let newExpr = AccessorDeclSyntax(accessorSpecifier: .keyword(.get)) {
                        "\(raw: containerArgument).resolve(\(typeName.trimmed).self)"
                    }
                    return [newExpr]
                }
            }
        }
        return []
    }
}

public struct ComponentMacro {
    enum ComponentDiagnostic: DiagnosticMessage {
        case notPublicInit
        case notPublicType
        case notClass
        case requiredModifierRequired
        
        public var message: String {
            switch self {
            case .notPublicInit:
                return "When using the @Component macro, if you implement the init() initializer, it must be public."
            case .notPublicType:
                return "@Component must be attached on public modifier."
            case .notClass:
                return "@Component can attached on class only."
            case .requiredModifierRequired:
                return "When using the @Component macro, if you implement the init() initializer in a non-final class, it must be required."
            }
        }
        
        public var diagnosticID: SwiftDiagnostics.MessageID {
            MessageID(domain: String(describing: self), id: String(describing: self))
        }
        
        public var severity: SwiftDiagnostics.DiagnosticSeverity {
            switch self {
            case .notPublicInit, .notPublicType, .notClass, .requiredModifierRequired:
                return .error
            }
        }
    }
}

extension ComponentMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let isNonFinalClass = {
            guard let classDeclaration = declaration.as(ClassDeclSyntax.self),
                  let modifiers = classDeclaration.modifiers.as(DeclModifierListSyntax.self) else {
                return false
            }
            let finalKeywordModifier = modifiers.compactMap { $0.as(DeclModifierSyntax.self) }
                .filter { $0.name.tokenKind == .keyword(.final) }
            return finalKeywordModifier.isEmpty
        }()
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
            let initializer = isNonFinalClass ? Self.requiredInitializer() : Self.initializer()
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
        
        if isNonFinalClass {
            let requiredInitializer = publicEmptyParameterInitializer.filter { initializerDeclaration in
                guard let modifiers = initializerDeclaration.modifiers.as(DeclModifierListSyntax.self) else {
                    return false
                }
                let requiredModifiers = modifiers
                    .compactMap { $0.as(DeclModifierSyntax.self) }
                    .filter {
                        return $0.name.tokenKind == .keyword(.required)
                    }
                return requiredModifiers.isEmpty == false
            }
            if requiredInitializer.isEmpty {
                context.diagnose(Diagnostic(node: node, message: ComponentDiagnostic.requiredModifierRequired))
                return []
            }
        }
        
        return []
    }
    
    private static func initializer() -> DeclSyntax {
        return """
        public init() {
        }
        """
    }
    
    private static func requiredInitializer() -> DeclSyntax {
        return """
        required public init() {
        }
        """
    }
}

extension ComponentMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard declaration.as(ClassDeclSyntax.self) != nil else {
            context.diagnose(Diagnostic(node: node, message: ComponentDiagnostic.notClass))
            return []
        }
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

public struct QualifierMacro: ExtensionMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return []
        }
        
        guard let qualifier = arguments
            .compactMap({ $0.as(LabeledExprSyntax.self) })
            .map({ $0.expression })
            .compactMap({ $0.as(StringLiteralExprSyntax.self) })
            .flatMap({ $0.segments })
            .compactMap({ $0.as(StringSegmentSyntax.self) })
            .map({ $0.content.text }).first else {
            return []
        }
        
        guard let extensionDeclSyntax = conformance(providingExtensionsOf: type, qualifier: qualifier).as(ExtensionDeclSyntax.self) else {
            return []
        }
        
        return [extensionDeclSyntax]
    }
    
    private static func conformance(providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, qualifier: String) -> DeclSyntax {
        return """
        extension \(type.trimmed): Qualifiable {
            var qualifier: String = "\(raw: qualifier)"
        }
        """
    }
}
