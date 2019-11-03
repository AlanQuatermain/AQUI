//
//  UnfairLock.swift
//  
//
//  Created by Jim Dovey on 11/3/19.
//

import os

public class UnfairLock {
    private var lock = os_unfair_lock()
    
    public func withLock<R>(block: () throws -> R) rethrows -> R {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        
        return try block()
    }
    
    public func tryLock<R>(block: () throws -> R) rethrows -> R? {
        if os_unfair_lock_trylock(&lock) {
            defer { os_unfair_lock_unlock(&lock) }
            return try block()
        }
        return nil
    }
}
