//
//  UIBackgroundTaskScheduler.swift
//  
//
//  Created by Jim Dovey on 11/2/19.
//

#if os(iOS) || os(tvOS)
import Combine
import UIKit

/// A special scheduler for Combine that wraps all downstream processing in a UIKit
/// background task. A single task is used to wrap all concurrent operations.
///
/// This scheduler assumes that everything downstream occurs synchronously. If you follow
/// it with a call to `.debounce()` or `.receive()`, then the background task will
/// exit at the point that operation takes over. You can use it as an argument to `.debounce()`
/// however.
@available(iOS 13.0, tvOS 13.0, *)
@available(OSX, unavailable)
@available(watchOS, unavailable)
public struct UIBackgroundTaskScheduler<Target: Scheduler>: Scheduler {
    // We pass through to another (real) scheduler, so use their types.
    public typealias SchedulerTimeType = Target.SchedulerTimeType
    public typealias SchedulerOptions = Target.SchedulerOptions
    
    /// A type used to manage shared data for copies of a `UIBackgroundTaskScheduler`.
    private class _Storage {
        /// The name used when creating the background task.
        let name: String?
        /// The task identifier currently in effect. `.invalid` if none in use.
        var taskID: UIBackgroundTaskIdentifier = .invalid
        /// A set of identifiers representing the waiting sub-tasks.
        var waitingTasks: Set<UUID> = []
        /// Cancellables generated for particular UUIDs, where they are available.
        var cancellables: [UUID: AnyCancellable] = [:]
        /// The dispatch queue used to lock access to the task ID variable.
        let lockQ = DispatchQueue(label: "AQUI.UIBackgroundTaskScheduler.TaskID.Lock")
        
        init(_ name: String? = nil) {
            self.name = name
        }
        
        /// Creates a background task if needed, then generates a unique ID for this instance
        /// and stores it in the set of waiting tasks.
        /// - returns: The unique identifier of this sub-task.
        func openTask() -> UUID {
            lockQ.sync {
                // Either we have no task ID, or we have one or more tasks.
                precondition(taskID == .invalid || !waitingTasks.isEmpty)
                
                if taskID == .invalid {
                    // No current task ID: create one.
                    taskID = UIApplication.shared.beginBackgroundTask(withName: name) {
                        self.taskExpired()
                    }
                }
                
                // Store an ident and return it.
                let ident = UUID()
                waitingTasks.insert(ident)
                return ident
            }
        }
        
        /// Called to remove a sub-task from the
        /// - Parameter uuid: <#uuid description#>
        func closeTask(_ uuid: UUID) {
            lockQ.sync {
                guard waitingTasks.contains(uuid) else {
                    // already cancelled/completed
                    return
                }
                waitingTasks.remove(uuid)
                cancellables.removeValue(forKey: uuid)  // we are never called before completion / cancellation
                if waitingTasks.isEmpty {
                    UIApplication.shared.endBackgroundTask(taskID)
                    taskID = .invalid
                }
            }
        }
        
        func setCancellable(_ cancellable: AnyCancellable?, for uuid: UUID) {
            cancellables[uuid] = cancellable
        }
        
        private func taskExpired() {
            lockQ.sync {
                // Cancel everything for which there's a cancellable.
                for uuid in waitingTasks {
                    if let cancellable = cancellables[uuid] {
                        cancellable.cancel()
                    }
                }
                if taskID != .invalid {
                    UIApplication.shared.endBackgroundTask(taskID)
                    taskID = .invalid
                }
            }
        }
    }
    
    /// Storage for the unified task system.
    private let storage: _Storage
    
    /// The target scheduler.
    private var target: Target
    
    /// Returns the wrapped scheduler's definition of the current moment in time.
    public var now: SchedulerTimeType { target.now }
    
    /// Returns the minimum tolerance allowed by the wrapped scheduler.
    public var minimumTolerance: SchedulerTimeType.Stride { target.minimumTolerance }

    /// Create a new scheduler that targets the given scheduler, wrapping all operations
    /// with a UIKit background task, optionally using a given name.
    ///
    /// - Parameters:
    ///   - name: The name given to each created background task
    ///   - target: The `Scheduler` to which operations are ultimately dispatched.
    public init(_ name: String? = nil, target: Target) {
        self.storage = _Storage(name)
        self.target = target
    }

    /// Performs the action at the next possible opportunity.
    public func schedule(options: Self.SchedulerOptions?, _ action: @escaping () -> Void) {
        let ident = storage.openTask()
        target.schedule(options: options) {
            action()
            self.storage.closeTask(ident)
        }
    }

    /// Performs the action at some time after the specified date.
    public func schedule(after date: Self.SchedulerTimeType, tolerance: Self.SchedulerTimeType.Stride, options: Self.SchedulerOptions?, _ action: @escaping () -> Void) {
        let ident = storage.openTask()
        target.schedule(after: date, tolerance: tolerance, options: options) {
            action()
            self.storage.closeTask(ident)
        }
    }
    
    /// Performs the action at some time after the specified date, at the specified
    /// frequency, optionally taking into account tolerance if possible.
    public func schedule(after date: Self.SchedulerTimeType, interval: Self.SchedulerTimeType.Stride, tolerance: Self.SchedulerTimeType.Stride, options: Self.SchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
        let ident = storage.openTask()
        let canceller = target.schedule(after: date, interval: interval, tolerance: tolerance, options: options) {
            action()
            self.storage.closeTask(ident)
        }
        
        // Notify storage that this ident is cancellable, and how.
        // Unfortunately using `AnyCancellable(canceler)` doesn't work. Le sigh.
        self.storage.setCancellable(AnyCancellable { canceller.cancel() }, for: ident)
        
        // return a wrapper that cleans up our storage
        return AnyCancellable {
            canceller.cancel()
            self.storage.closeTask(ident)
        }
    }
}
#endif
