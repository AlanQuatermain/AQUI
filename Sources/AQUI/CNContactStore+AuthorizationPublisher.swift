//
//  File.swift
//  
//
//  Created by Jim Dovey on 11/2/19.
//

#if os(iOS) || os(macOS)
import Contacts
import Combine

extension CNContactStore {
    public func publisherForAccessRequest(for entityType: CNEntityType) -> PassthroughSubject<Bool, Error> {
        let subject = PassthroughSubject<Bool, Error>()
        self.requestAccess(for: entityType) { success, error in
            precondition(success || error != nil)
            
            if success {
                subject.send(true)
                subject.send(completion: .finished)
            }
            else {
                subject.send(completion: .failure(error!))
            }
        }
        
        return subject
    }
}
#endif
