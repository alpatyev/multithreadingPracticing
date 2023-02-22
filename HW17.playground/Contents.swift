import Foundation

// MARK: - LIFO storage implementation

struct Stack<Element> {
    private var storageLock = NSRecursiveLock()
    private var stack = [Element]()

    var count: Int { stack.count }
    var isEmpty: Bool { peek() == nil }
    
    func peek() -> Element? { stack.last }
    mutating func push(_ element: Element) {
        safely { self.stack.append(element) }
    }
    mutating func pop() -> Element? {
        var element: Element?
        safely { element = self.stack.popLast() }
        return element
    }
    
    private func safely(completion: () -> Void) {
        storageLock.lock()
        completion()
        storageLock.unlock()
    }}

// MARK: - Generator thread

final class GeneratorThread: Thread {
    
    // MARK: - Worker delegate
    
    weak var delegate: WorkerThreadDelegate?

    // MARK: - Thread-safe storage
    
    private var storage = Stack<Chip>() {
        didSet {
            delegate?.soderLastChip(storage.peek())
        }
    }
    
    // MARK: - Generator main
    
    override func main() {
       startGenerating()
    }
    
    // MARK: - Private methods
    
    private func startGenerating() {
        let endTime = Date().addingTimeInterval(20)
        while Date() < endTime {
            print("\(String.currentTime()) - generate one on thread: \(Thread.current.name ?? "?")")
            storage.push(Chip.make())
            Thread.sleep(forTimeInterval: 2)
        }
        storage.push(Chip.make())
        print("\(String.currentTime()) - last one thread: \(Thread.current.name ?? "?")")
        print(storage.count)
    }
}

// MARK: - Worker thread

protocol WorkerThreadDelegate: AnyObject {
    func soderLastChip(_ chip: Chip?)
}

final class WorkerThread: Thread, WorkerThreadDelegate {
    func soderLastChip(_ chip: Chip?) {
        guard let chip = chip else {
            print("No chip recieved")
            return
        }
        print("\(String.currentTime()) - soldering on thread: \(Thread.current.name ?? "?") - chip: \(chip.chipType)")
        chip.sodering()
    }
}

let generator = GeneratorThread()
let worker = WorkerThread()
worker.name = "worker"
generator.delegate = worker
generator.name = "generator"

worker.start()
generator.start()
