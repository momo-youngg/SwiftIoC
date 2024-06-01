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
public macro Autowired(container: DependencyResolvable = DIContainer.shared) = #externalMacro(module: "SwiftIoCMacros", type: "AutowiredMacro")

@attached(member, names: named(init))
@attached(extension, conformances: Componentable)
public macro Component() = #externalMacro(module: "SwiftIoCMacros", type: "ComponentMacro")

@attached(extension, conformances: Qualifiable)
@attached(member, names: named(_qualifier))
public macro Qualifier(_ qualifier: String) = #externalMacro(module: "SwiftIoCMacros", type: "QualifierMacro")

@attached(peer)
public macro Qualified(_ qualifier: String) = #externalMacro(module: "SwiftIoCMacros", type: "QualifiedMacro")
