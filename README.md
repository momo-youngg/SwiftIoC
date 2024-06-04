# SwiftIoC
SwiftIoC is a Dependency Injection (DI) container for Swift, inspired by Spring IoC. It uses Swift macros to simplify the process of dependency registration and injection.

## Features
- Automatic dependency registration using `@Component` macro
- Automatic dependency injection using `@Autowired` macro
- Support for qualifiers with @Qualifier and `@Qualified` macros
- Simple and clean API

## Installation
To install SwiftIoC, you can use Swift Package Manager. Add the following to your Package.swift file:
```swift
dependencies: [
    .package(url: "https://github.com/momo-youngg/SwiftIoC.git", from: "0.0.1")
]
```

## Usage
### Registering Dependencies
Use the `@Component` macro to register a class as a dependency:
```swift
@Component
public class MyComponent {
    public func doSomething() {
        print("Doing something...")
    }
}
```
### Injecting Dependencies
Use the `@Autowired` macro to inject dependencies:
```swift
@Component
public class OtherComponent {
    
    @Autowired
    private var myComponent: MyComponent

    public func execute() {
        myComponent.doSomething()
    }
}
```
### Using Qualifiers
To inject specific implementations when multiple candidates exist, use `@Qualifier` and `@Qualified` macros:
```swift
protocol MyProtocol {
    func doSomething()
}

@Component
@Qualifier("First")
public class FirstComponent: MyProtocol {
    public func doSomething() {
        print("Doing First something...")
    }
}

@Component
@Qualifier("Second")
public class SecondComponent: MyProtocol {
    public func doSomething() {
        print("Doing Second something...")
    }
}

@Component
public class OtherComponent {

    @Autowired
    @Qualified("Second")
    private var myComponent: MyProtocol

    public func execute() {
        myComponent.doSomething()
    }
}
```

## Limitations and Future Directions
- Type Constraints: Only class types can be used due to the reliance on objc_getClassList.
- Overhead on First Query: The first dependency query involves scanning all types and instantiating Componentable types.
- Repeated Query Overhead: Each dependency access involves querying the DIContainer.
- No SwiftUI ObservedObject Support: The current approach using getters does not support ObservedObject.
- Generic Type Support: Currently, generic types cannot be directly instantiated and registered.

### Future Improvements
- Improve type-checking to allow selective instantiation of required types only.
- Resolve lazy var macro compilation issues to reduce repeated query overhead.
- Add support for already instantiated dependencies for better generic type support.

## Contributing
Contributions are welcome! Please submit pull requests or open issues to discuss potential improvements or features.

## License
SwiftIoC is released under the MIT License. See LICENSE for details.

## Contact
For any questions or suggestions, please open an issue
