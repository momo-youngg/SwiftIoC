//
//  QualifierMacro.swift
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

public struct QualifierMacro: ExtensionMacro {
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
        extension \(type.trimmed): Qualifiable {
        }
        """
    }
}

extension QualifierMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
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

        return [Self.qualifier(qualifier)]
    }
    
    private static func qualifier(_ qualifier: String) -> DeclSyntax {
        return """
        public var _qualifier: String = "\(raw: qualifier)"
        """
    }
}
