//
//  DIContainer.swift
//
//
//  Created by momo on 6/1/24.
//

import Foundation

@objc public protocol Componentable {
    init()
}

public protocol DependencyResolvable {
    func resolve<T: Componentable>(_ type: T.Type, qualifier: String?) -> T
}

public final class DIContainer: DependencyResolvable {
    public static let shared: DIContainer = .init()
    
    private var cache: [CacheKey: Any] = [:]
    
    public func resolve<T>(_ type: T.Type, qualifier: String? = nil) -> T {
        self.queue.sync {
            let key = self.cacheKey(type)
            if let cached = self.cache[key], let transformed = cached as? T {
                return transformed
            }
            
            let targets = self.allComponentableInstances
                .compactMap { $0 as? T }
                .filter { candidate in
                    guard let qualifier = qualifier else {
                        return true
                    }
                    guard let qualifiable = candidate as? Qualifiable else {
                        return false
                    }
                    return qualifiable._qualifier == qualifier
                }
            
            if let target = targets.first {
                self.cache[key] = target
                return target
            }
            
            fatalError()
        }
    }
    
    private let queue = DispatchQueue(label: "DIContainer")
    
    private lazy var allComponentableInstances: [Componentable] = {
        let allClassesInTarget = self.getAllClassesInTarget()
        let componentables = allClassesInTarget
            .filter { class_conformsToProtocol($0, Componentable.self) }
            .compactMap { $0 as? Componentable.Type }
        let initicated = componentables.map { $0.init() }
        return initicated
    }()
    
    private struct CacheKey: Hashable {
        let type: String
        let qualifier: String?
        
        init<T>(type: T.Type, qualifier: String?) {
            self.type = String(describing: type)
            self.qualifier = qualifier
        }
    }
    
    private func cacheKey<T>(_ type: T.Type, qualifier: String? = nil) -> CacheKey {
        CacheKey(type: type, qualifier: qualifier)
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

public protocol Qualifiable {
    var _qualifier: String { get }
}
