//
//  DIContainer.swift
//
//
//  Created by momo on 6/1/24.
//

import Foundation

public final class DIContainer: DependencyResolvable {
    public static let shared: DIContainer = .init()
    
    private var cache: [CacheKey: Any] = [:]
    
    private let queue = DispatchQueue(label: "DIContainer")
    
    private lazy var allComponentableInstances: [Componentable] = {
        let allClassesInTarget = self.getAllClassesInTarget()
        let componentables = allClassesInTarget
            .filter { class_conformsToProtocol($0, Componentable.self) }
            .compactMap { $0 as? Componentable.Type }
        let initiated = componentables.map { $0.init() }
        return initiated
    }()

    public func resolve<T>(_ type: T.Type, qualifier: String? = nil) -> T {
        self.queue.sync {
            let key = self.cacheKey(type, qualifier: qualifier)
            if let cached = self.cache[key], let transformed = cached as? T {
                return transformed
            }
            
            let satisfiedInstances = self.allComponentableInstances
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
            
            if satisfiedInstances.count >= 2 {
                fatalError(DIContainerError.moreThanTwoCandidateDependency.message)
            }
            
            if let target = satisfiedInstances.first {
                self.cache[key] = target
                return target
            }
            
            fatalError(DIContainerError.canNotFind.message)
        }
    }
    
}

extension DIContainer {
    private enum DIContainerError {
        case moreThanTwoCandidateDependency
        case canNotFind
        
        var message: String {
            switch self {
            case .moreThanTwoCandidateDependency:
                return "There is more than 2 candidate dependency found. Use @Qualifier, @Qualified to distinguish which dependency to use."
            case .canNotFind:
                return "There is no dependency found."
            }
        }
    }
    
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

        let allClasses = UnsafeMutablePointer<AnyClass>.allocate(capacity: Int(classCount))
        defer { allClasses.deallocate() }

        let releasingPointer = AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses)
        objc_getClassList(releasingPointer, classCount)

        let bufferPointer = UnsafeBufferPointer(start: allClasses, count: Int(classCount))
        let array = Array(bufferPointer)
        
        return array
    }
}
