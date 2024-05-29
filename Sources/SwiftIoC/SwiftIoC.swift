// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "SwiftIoCMacros", type: "StringifyMacro")

@attached(accessor)
@attached(peer, names: prefixed(_))
public macro Autowired(container: DIContainer = DefaultDIContainer.shared) = #externalMacro(module: "SwiftIoCMacros", type: "AutowiredMacro")

@attached(member, names: named(init))
@attached(extension, conformances: Componentable)
public macro Component() = #externalMacro(module: "SwiftIoCMacros", type: "ComponentMacro")

public protocol Componentable {
    init()
}

public protocol DIContainer {
    func resolve<T: Componentable>(_ type: T.Type) -> T
}

public final class DefaultDIContainer: DIContainer {
    public static let shared: DefaultDIContainer = .init()
    
    public func resolve<T>(_ type: T.Type) -> T where T : Componentable {
        return .init()
    }
}
