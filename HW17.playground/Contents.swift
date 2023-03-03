import Foundation

// MARK: - LIFO data type

struct Stack<Chip> {
    
    private let storageLock = NSRecursiveLock()
    private var stack = [Chip]()
    
    mutating func push(_ element: Chip) { safely { self.stack.append(element) } }
    mutating func pop() -> Chip? {
        var element: Chip?
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

final class ChipStorage {
    
    public let condition = NSCondition()
    public var stack = Stack<Chip>() {
        didSet {
            condition.signal()
        }
    }
}

// MARK: - Generator thread

final class GeneratorThread: Thread {
        
    private let storage: ChipStorage
        
    init(with storage: ChipStorage) {
        self.storage = storage
        super.init()
        name = "generator"
    }
        
    override func main() {
        let endTime = Date().addingTimeInterval(20)
        while Date() < endTime {
            let chip = Chip.make()
            print("* \(String.currentTime()) * THREAD: [\(Thread.current.name ?? "no name")] generated chip.\(chip.chipType)")
            storage.stack.push(chip)
            Thread.sleep(forTimeInterval: 2)
        }
    }
}

// MARK: - Worker thread


final class WorkerThread: Thread {
    
    private var storage: ChipStorage
    private let condition: NSCondition
    
    init(with storage: ChipStorage) {
        self.storage = storage
        self.condition = storage.condition
        super.init()
        name = "  worker "
    }
    
    override func main() {
        while true {
            if let chip = storage.stack.pop() {
                print("* \(String.currentTime()) * THREAD: [\(Thread.current.name ?? "no name")] soldered chip.\(chip.chipType)")
                chip.sodering()
            } else {
                condition.wait()
            }
        }
    }
}

// MARK: - Using

let storage = ChipStorage()
let worker = WorkerThread(with: storage)
let generator = GeneratorThread(with: storage)

worker.start()
generator.start()
