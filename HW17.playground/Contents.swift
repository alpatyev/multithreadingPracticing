import Foundation

// MARK: - LIFO storage implementation

protocol EquatableStack {
    associatedtype Element
}

struct Stack<Element>: EquatableStack where Element: Equatable {
    private var storage = [Element]()
    var isEmpty: Bool { peek() == nil }
    func peek() -> Element? { storage.last }
    mutating func push(_ element: Element) { storage.append(element)  }
    mutating func pop() -> Element? { storage.popLast() }
}
