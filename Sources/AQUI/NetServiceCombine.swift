//
//  NetServiceCombine.swift
//  
//
//  Created by Jim Dovey on 11/3/19.
//

import Foundation
import Combine
import os

fileprivate func error(from errorDict: [String : NSNumber]) -> Error {
    let code: Int = errorDict[NetService.errorCode]!.intValue
    return NSError(domain: NetService.errorDomain, code: code, userInfo: errorDict)
}

fileprivate class NetServicePublishingDelegate: NSObject, NetServiceDelegate {
    fileprivate let subject = PassthroughSubject<NetService.Event, Never>()
    
    deinit {
        subject.send(completion: .finished)
    }
    
    func netServiceDidPublish(_ sender: NetService) {
        subject.send(.didPublish(nil))
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        subject.send(.didPublish(error(from: errorDict)))
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        subject.send(.resolvedAddress(.success(sender.addresses!)))
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        subject.send(.resolvedAddress(.failure(error(from: errorDict))))
    }

    func netServiceDidStop(_ sender: NetService) {
        subject.send(.stopped)
    }

    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        subject.send(.txtRecordUpdated(data))
    }

    func netService(_ sender: NetService, didAcceptConnectionWith inputStream: InputStream, outputStream: OutputStream) {
        subject.send(.acceptedConnection(inputStream, outputStream))
    }
}

fileprivate class NetBrowserPublishingDelegate: NSObject, NetServiceBrowserDelegate {
    fileprivate let domainSubject = PassthroughSubject<NetServiceBrowser.Event<String>, Error>()
    fileprivate let serviceSubject = PassthroughSubject<NetServiceBrowser.Event<NetService>, Error>()
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        domainSubject.send(completion: .finished)
        serviceSubject.send(completion: .finished)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        let err = error(from: errorDict)
        domainSubject.send(completion: .failure(err))
        serviceSubject.send(completion: .failure(err))
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
        domainSubject.send(.appeared(domainString))
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        serviceSubject.send(.appeared(service))
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        domainSubject.send(.disappeared(domainString))
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        serviceSubject.send(.disappeared(service))
    }
}

fileprivate var servicePublishingDelegates: [ObjectIdentifier: NetServicePublishingDelegate] = [:]
fileprivate let serviceLock = UnfairLock()

extension NetService {
    public enum Event {
        case didPublish(Error?)
        case resolvedAddress(Result<[Data],Error>)
        case stopped
        case txtRecordUpdated(Data)
        case acceptedConnection(InputStream, OutputStream)
    }
    
    public var publisher: AnyPublisher<Event, Never> {
        serviceLock.withLock {
            if let publishingDelegate = delegate as? NetServicePublishingDelegate {
                // already have a delegate, just return its publisher
                return publishingDelegate.subject.eraseToAnyPublisher()
            }
            
            if let delegate = self.delegate {
                // warn about the delegate being replaced
                os_log(.default, "%{public}s: delegate already installed: %{public}s",
                       #function, String(describing: delegate))
            }
            
            let newDelegate = NetServicePublishingDelegate()
            servicePublishingDelegates[ObjectIdentifier(self)] = newDelegate
            self.delegate = newDelegate
            return newDelegate.subject.eraseToAnyPublisher()
        }
    }
}

fileprivate var browserPublishingDelegates: [ObjectIdentifier: NetBrowserPublishingDelegate] = [:]
fileprivate let browserLock = UnfairLock()

extension NetServiceBrowser {
    public enum Event<Value> {
        case appeared(Value)
        case disappeared(Value)
    }
    
    public var domainPublisher: AnyPublisher<Event<String>, Error> {
        browserLock.withLock {
            if let publishingDelegate = delegate as? NetBrowserPublishingDelegate {
                // already have one ready
                return publishingDelegate.domainSubject.eraseToAnyPublisher()
            }
            
            if let delegate = self.delegate {
                // warn about the delegate being replaced
                os_log(.default, "%{public}s: delegate already installed: %{public}s",
                       #function, String(describing: delegate))
            }
            
            let newDelegate = NetBrowserPublishingDelegate()
            browserPublishingDelegates[ObjectIdentifier(self)] = newDelegate
            self.delegate = newDelegate
            return newDelegate.domainSubject.eraseToAnyPublisher()
        }
    }
    
    public var servicePublisher: AnyPublisher<Event<NetService>, Error> {
        browserLock.withLock {
            if let publishingDelegate = delegate as? NetBrowserPublishingDelegate {
                // already have one ready
                return publishingDelegate.serviceSubject.eraseToAnyPublisher()
            }
            
            if let delegate = self.delegate {
                // warn about the delegate being replaced
                os_log(.default, "%{public}s: delegate already installed: %{public}s",
                       #function, String(describing: delegate))
            }
            
            let newDelegate = NetBrowserPublishingDelegate()
            browserPublishingDelegates[ObjectIdentifier(self)] = newDelegate
            self.delegate = newDelegate
            return newDelegate.serviceSubject.eraseToAnyPublisher()
        }
    }
}
