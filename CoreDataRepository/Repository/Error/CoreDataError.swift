//
//  CoreDataError.swift
//  CoreDataRepository
//
//  Created by Евгений Самарин on 04.05.2022.
//

import Foundation

enum CoreDataError: Error {

    case readError(Error)
    case saveError(Error)
    case deleteError(Error)
    case noChangesInRepository
    case noDataInRepository
    case entityTypeError
}
