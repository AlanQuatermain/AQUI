//
//  UnfairLock.swift
//  
//
//  Created by Jim Dovey on 11/3/19.
//

import os

public class UnfairLock {
    private let lock: UnsafeMutablePointer<os_unfair_lock>
    
    init() {
        lock = .allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
    }
    
    deinit {
        lock.deallocate()
    }
    
    public func withLock<R>(block: () throws -> R) rethrows -> R {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        
        return try block()
    }
    
    public func tryLock<R>(block: () throws -> R) rethrows -> R? {
        if os_unfair_lock_trylock(lock) {
            defer { os_unfair_lock_unlock(lock) }
            return try block()
        }
        return nil
    }
}
