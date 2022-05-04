//
//  DefaultDBContextProvider.swift
//  CoreDataRepository
//
//  Created by Евгений Самарин on 04.05.2022.
//

import CoreData
import Combine

final class DefaultDBContextProvider {

    // MARK: - Instance Properties

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataStorageModel")
     
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error),\(error.userInfo)")
            }
            container.viewContext.automaticallyMergesChangesFromParent = true
        })
        return container
    }()
    private lazy var mainContext = persistentContainer.viewContext
}

//MARK: - DBContextProvider implementation

extension DefaultDBContextProvider: DBContextProvider {

    // MARK: - DBContextProvider Methods

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        self.persistentContainer.performBackgroundTask(block)
    }

    func mainQueueContext() -> NSManagedObjectContext {
        self.mainContext
    }
}
