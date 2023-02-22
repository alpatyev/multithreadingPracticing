import Foundation
import Darwin

// MARK: - LIFO storage data type implementation

struct Stack<Element> {
    
    private let storageLock = NSRecursiveLock()
    private var stack = [Element]()

    var isEmpty: Bool { peek() == nil }
    var count: Int { stack.count }
    
    func peek() -> Element? { stack.last }
    mutating func push(_ element: Element) { safely { self.stack.append(element) } }
    mutating func pop() -> Element? {
        var element: Element?
        safely { element = self.stack.popLast() }
        return element
    }
    
    private func safely(completion: () -> Void) {
        storageLock.lock()
        completion()
        storageLock.unlock()
    }
}

// MARK: - Storage

protocol StorageDelegate {
    var isEmpty: Bool { get }
    var worker: WorkerDelegate? { get set }
    func popLast() -> Chip?
}

final class ChipStorage: StorageDelegate {
    
    var isEmpty: Bool { stack.isEmpty }
    var worker: WorkerDelegate?
    var generator: GeneratorThread?
    
    public var stack = Stack<Chip>() {
        didSet {
            worker?.storageUpdated()
            print("* \(String.currentTime()) * THREAD: [\(Thread.current.name ?? "no name")] storage updated with \(stack.count) chips")
        }
    }
    
    func popLast() -> Chip? {
        stack.pop()
    }
    
    func getCount() -> Int {
        stack.count
    }
    
    public func generated(new chip: Chip) {
        stack.push(chip)
    }
}

// MARK: - Generator thread

final class GeneratorThread: Thread {
        
    let storage: ChipStorage
        
    init(with storage: ChipStorage) {
        self.storage = storage
        super.init()
        name = "generator"
    }
        
    override func main() {
        print("* \(String.currentTime()) * THREAD: [\(Thread.current.name ?? "no name")] * STARTED * ")
        var count = 0
        let endTime = Date().addingTimeInterval(20)
        while Date() < endTime {
            count += 1
            let chip = Chip.make()
            print("* \(String.currentTime()) * THREAD: [\(Thread.current.name ?? "no name")] generated new chip with type \(chip.chipType)")
            storage.generated(new: chip)
            Thread.sleep(forTimeInterval: 2)
        }
        print("* \(String.currentTime()) * THREAD: [\(Thread.current.name ?? "no name")] * ENDED * RESULT \(count) chips")
    }
}

// MARK: - Worker thread

protocol WorkerDelegate {
    var storage: StorageDelegate? { get set }
    func storageUpdated()
}

final class WorkerThread: Thread, WorkerDelegate {
    
    var storage: StorageDelegate?
    private var count = 0
    private var isWorking = false
    private let condition = NSCondition()
    
    init(with storage: ChipStorage) {
        self.storage = storage
        super.init()
        name = "  worker "
        storage.worker = self
    }
    
    override func main() {
        print("* \(String.currentTime()) * THREAD: [\(Thread.current.name ?? "no name")] * STARTED * ")
        while true {
            isWorking = true
            if let chip = storage?.popLast() {
                count += 1
                print("* \(String.currentTime()) * THREAD: [\(Thread.current.name ?? "no name")] soldering chip with type \(chip.chipType)")
                chip.sodering()
            } else {
                if let pointer = storage, pointer.isEmpty {
                    cancel()
                }
                condition.wait()
            }
            isWorking = false
        }
    }
    
    override func cancel() {
        print("* \(String.currentTime()) * THREAD: [\(Thread.current.name ?? "no name")] * ENDED * RESULT \(count) chips")
    }
    
    func storageUpdated() {
        condition.signal()
    }
}

// MARK: - Using

let storage = ChipStorage()
let worker = WorkerThread(with: storage)
let generator = GeneratorThread(with: storage)

worker.start()
generator.start()
