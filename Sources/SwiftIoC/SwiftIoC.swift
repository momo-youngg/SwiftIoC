// The Swift Programming Language
// https://docs.swift.org/swift-book

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
