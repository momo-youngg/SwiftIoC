//
//  AutowiredMacro.swift
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
        guard let variableDecl = declaration.as(VariableDeclSyntax.self),
              variableDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
            context.diagnose(Diagnostic(node: node, message: AutowiredDiagnostic.notVariableProperty))
            return []
        }
        
        if let bindings = variableDecl.bindings.as(PatternBindingListSyntax.self) {
            // equal must not exist
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
            
            // accessor must not exist
            let accessorBlock = bindings
                .compactMap { $0.as(PatternBindingSyntax.self) }
                .compactMap { $0.accessorBlock }
            if accessorBlock.isEmpty == false {
                context.diagnose(Diagnostic(node: node, message: AutowiredDiagnostic.storedProperty))
                return []
            }
            
            // get DIContainer argument name
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
            
            // get type name
            if let typeName = bindings
                .compactMap({ $0.as(PatternBindingSyntax.self) })
                .compactMap({ $0.typeAnnotation })
                .compactMap({ $0.as(TypeAnnotationSyntax.self) })
                .map({ $0.type })
                .compactMap({ $0.as(IdentifierTypeSyntax.self) })
                .map({ $0.name })
                .first {
                
                // get qualifier if exists
                if let qualifier = variableDecl
                    .attributes
                    .compactMap({ $0.as(AttributeSyntax.self) })
                    .filter({ $0.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "Qualified" })
                    .compactMap({ $0.arguments })
                    .compactMap({ $0.as(LabeledExprListSyntax.self) })
                    .flatMap({ $0 })
                    .compactMap({ $0.as(LabeledExprSyntax.self) })
                    .compactMap({ $0.expression.as(StringLiteralExprSyntax.self) })
                    .flatMap({ $0.segments })
                    .compactMap({ $0.as(StringSegmentSyntax.self) })
                    .map({ $0.content.text }).first {
                    // inject with qualifier
                    let newExpr = AccessorDeclSyntax(accessorSpecifier: .keyword(.get)) {
                        "\(raw: containerArgument).resolve(\(typeName.trimmed).self, qualifier: \"\(raw: qualifier)\")"
                    }
                    return [newExpr]
                } else {
                    // inject without qualifier
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

