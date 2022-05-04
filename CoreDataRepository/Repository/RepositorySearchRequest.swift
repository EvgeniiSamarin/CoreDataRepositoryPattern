//
//  RepositorySearchRequest.swift
//  CoreDataRepository
//
//  Created by Евгений Самарин on 04.05.2022.
//

import Foundation

protocol RepositorySearchRequest {

    // MARK: - Instance Properties

    var predicate: NSPredicate? { get }
    var sortDescriptors: [NSSortDescriptor] { get }
}
