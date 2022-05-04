//
//  DBContextProvider.swift
//  CoreDataRepository
//
//  Created by Евгений Самарин on 04.05.2022.
//

import CoreData
import Combine

protocol DBContextProvider {

    // MARK: - Instance Methods

    func mainQueueContext() -> NSManagedObjectContext
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)
}
