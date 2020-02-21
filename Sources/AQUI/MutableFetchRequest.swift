//
//  FetchRequest.swift
//
//
//  Created by Jim Dovey on 11/21/19.
//

import Foundation
import SwiftUI
import CoreData
import os

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@propertyWrapper
public struct MutableFetchRequest<Result: NSFetchRequestResult>: DynamicProperty {
    /// Using `@Boxed` to get a `nonmutating set`, otherwise any
    /// structure containing a `MutableFetchRequest` will be unable to change the
    /// `fetchRequest` without itself being mutable.
    @Boxed private var requestBox: NSFetchRequest<Result>

    /// The underlying `NSFetchRequest` used to query the data store. This value is copied in, not
    /// retained, so the property will need to be re-set following any changes.
    public var fetchRequest: NSFetchRequest<Result> {
        get { requestBox }
        nonmutating set {
            requestBox = newValue.copy() as! NSFetchRequest<Result>
            
            // Trigger SwiftUI attribute graph refresh.
            results = nil
        }
    }

    /// State value so controller can update it, triggering SwiftUI rendering.
    @State private var results: MutableFetchedResults<Result>?
    /// State value to share it across multiple copies of this structure.
    @State private var controller = Controller()

    /// The transaction used when updating the results.
    private var transaction: Transaction

    /// The managed object context used to present changes, fetched from the SwiftUI environment.
    @Environment(\.managedObjectContext) var managedObjectContext

    /// Creates an instance from a fetch request.
    /// - Parameters:
    ///   - fetchRequest: The request used to produce the fetched results.
    ///   - transaction: The transaction used for any changes to the fetched
    ///     results.
    public init(fetchRequest: NSFetchRequest<Result>, transaction: Transaction) {
        self._requestBox = Box(wrappedValue: fetchRequest)
        self.transaction = transaction
    }

    /// Creates an instance from a fetch request.
    /// - Parameters:
    ///   - fetchRequest: The request used to produce the fetched results.
    ///   - animation: The animation used for any changes to the fetched
    ///     results.
    public init(fetchRequest: NSFetchRequest<Result>, animation: Animation? = nil) {
        self.init(fetchRequest: fetchRequest, transaction: Transaction(animation: animation))
    }

    /// Creates an instance by defining a fetch request based on the parameters.
    /// - Parameters:
    ///   - entity: The kind of modeled object to fetch.
    ///   - sortDescriptors: An array of sort descriptors defines the sort
    ///     order of the fetched results.
    ///   - predicate: An NSPredicate defines a filter for the fetched results.
    ///   - animation: The animation used for any changes to the fetched
    ///     results.
    public init(entity: NSEntityDescription, sortDescriptors: [NSSortDescriptor], predicate: NSPredicate? = nil, animation: Animation? = nil) {
        let request: NSFetchRequest<Result> = NSFetchRequest()
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        self.init(fetchRequest: request, animation: animation)
    }

    public mutating func update() {
        guard managedObjectContext.persistentStoreCoordinator != nil else {
            os_log(.fault, "Context in environment is not connected to a persistent store coordinator: %@", managedObjectContext)
            return
        }

        if self.fetchRequest != controller.fetchedResultsController?.fetchRequest {
            controller.fetchedResultsController = nil
        }
        if controller.fetchedResultsController == nil {
            controller.fetchedResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest.copy() as! NSFetchRequest<Result>,
                managedObjectContext: managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil)
            controller.results = $results
            controller.transaction = transaction
            controller.fetchedResultsController?.delegate = controller
            do {
                try controller.fetchedResultsController?.performFetch()
            }
            catch {
                os_log(.fault, "Failed to perform fetch request: %@", error.localizedDescription)
            }
        }
    }

    /// The current collection of fetched results.
    public var wrappedValue: MutableFetchedResults<Result> {
        if let results = results { return results }
        let objects = controller.fetchedResultsController?.fetchedObjects
        return MutableFetchedResults(objects: objects as NSArray? ?? NSArray())
    }

    /// The controller used to manage the `NSFetchedResultsController` and serve
    /// as its delegate. Feeds updates back to the `MutableFetchRequest` via
    /// a `Binding`.
    class Controller: NSObject, NSFetchedResultsControllerDelegate {
        /// The task of dealing with a mutating data store is delegated to this
        /// fetched results controller instance, created on demand.
        var fetchedResultsController: NSFetchedResultsController<Result>? = nil
        /// Updates must be assigned using a transaction.
        var transaction: Transaction? = nil
        /// The binding to the shared state storage from which the results are read.
        var results: Binding<MutableFetchedResults<Result>?>? = nil

        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            guard let results = results else { return }
            let objects = controller.fetchedObjects as NSArray? ?? NSArray()
            let value = MutableFetchedResults<Result>(objects: objects)

            if let transaction = transaction {
                results.transaction(transaction).wrappedValue = value
            }
        }
    }
}

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension MutableFetchRequest where Result : NSManagedObject {
    /// Creates an instance by defining a fetch request based on the parameters.
    /// The fetch request will automatically infer the entity using Result.entity().
    /// - Parameters:
    ///   - sortDescriptors: An array of sort descriptors defines the sort
    ///     order of the fetched results.
    ///   - predicate: An NSPredicate defines a filter for the fetched results.
    ///   - animation: The animation used for any changes to the fetched
    ///     results.
    public init(sortDescriptors: [NSSortDescriptor], predicate: NSPredicate? = nil, animation: Animation? = nil) {
        let request: NSFetchRequest<Result> = NSFetchRequest()
        request.entity = Result.entity()
        request.sortDescriptors = sortDescriptors
        request.predicate = predicate
        self.init(fetchRequest: request, animation: animation)
    }
}

/// The MutableFetchedResults collection type represents the results of performing a
/// fetch request. Internally, it may use strategies such as batching and
/// transparent futures to minimize memory use and I/O.
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct MutableFetchedResults<Result>: RandomAccessCollection where Result: NSFetchRequestResult {
    /// CoreData returns a special `NSArray` subclass that performs faulting and batching,
    /// so to preserve that behavior we need to keep a reference to that class.
    fileprivate let objects: NSArray

    public var startIndex: Int { 0 }
    public var endIndex: Int { objects.count }
    public subscript(position: Int) -> Result { objects.object(at: position) as! Result }
}
