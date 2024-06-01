//
//  ComponentMacro.swift
//  
//
//  Created by momo on 6/2/24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

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
        guard let typeModifiers = declaration.modifiers.as(DeclModifierListSyntax.self) else {
            return []
        }
        
        // check if access modifier is public
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
        
        let isNonFinalClass = {
            guard let classDeclaration = declaration.as(ClassDeclSyntax.self),
                  let modifiers = classDeclaration.modifiers.as(DeclModifierListSyntax.self) else {
                return false
            }
            let finalKeywordModifier = modifiers.compactMap { $0.as(DeclModifierSyntax.self) }
                .filter { $0.name.tokenKind == .keyword(.final) }
            return finalKeywordModifier.isEmpty
        }()
        
        // check if init() is exists already
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
        
        // check if exist init() is public
        guard publicEmptyParameterInitializer.isEmpty == false else {
            context.diagnose(Diagnostic(node: node, message: ComponentDiagnostic.notPublicInit))
            return []
        }
        
        // check if exist init() and type has final keyword but no required init()
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
