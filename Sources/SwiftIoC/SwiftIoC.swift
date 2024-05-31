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

@objc public protocol Componentable {
    init()
}

public protocol DependencyResolvable {
    func resolve<T: Componentable>(_ type: T.Type) -> T
}

import Foundation

public final class DIContainer: DependencyResolvable {
    public static let shared: DIContainer = .init()
    
    private var cache: [String: Any] = [:]
    
    public func resolve<T>(_ type: T.Type) -> T {
        let key = self.cacheKey(type)
        if let cached = self.cache[key], let transformed = cached as? T {
            return transformed
        }
        
        let targets = self.allComponentableInstances.compactMap { $0 as? T }
        
        if let target = targets.first {
            self.cache[key] = target
            return target
        }
        
        fatalError()
    }
    
    private lazy var allComponentableInstances: [Componentable] = {
        let allClassesInTarget = self.getAllClassesInTarget()
        let componentables = allClassesInTarget
            .filter { class_conformsToProtocol($0, Componentable.self) }
            .compactMap { $0 as? Componentable.Type }
        let initicated = componentables.map { $0.init() }
        return initicated
    }()
    
    private func cacheKey<T>(_ type: T.Type) -> String {
        String(describing: type)
    }
    
    private func getAllClassesInTarget() -> [AnyClass] {
        let classCount = objc_getClassList(nil, 0)
        guard classCount > 0 else {
            return []
        }

        let allClasses = UnsafeMutablePointer<AnyClass>.allocate(capacity: Int(classCount))
        defer { allClasses.deallocate() }

        let releasingPointer = AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses)
        objc_getClassList(releasingPointer, classCount)

        // 포인터에서 배열로 변환
        let bufferPointer = UnsafeBufferPointer(start: allClasses, count: Int(classCount))
        let array = Array(bufferPointer)
        
        return array
    }
}
