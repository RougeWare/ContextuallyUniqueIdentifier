//
//  AppUniqueIdentifier.swift
//
//
//  Created by Ky Leggiero on 2022-07-08.
//

import Foundation



/// An identifier which is unique to this app's runtime.
///
/// This is only guaranteed to be unique in this app's runtime. Any further uniqueness is not guaranteed.
public struct AppUniqueIdentifier {
    private let rawValue: ID
}



// MARK: - Private APIs

// MARK: Initialization

fileprivate extension AppUniqueIdentifier {
    
    /// Creates a new app-unique ID with the given value. This also registers it immediately, to ensure all app-unique IDs are unique across all others
    ///
    /// - Parameter id: The value of the new app-unique ID
    init(id: ID) {
        self.rawValue = id
        
        Self.register(id: self)
    }
}


// MARK: Static registry

fileprivate extension AppUniqueIdentifier {
    
    /// The IDs which are currently in use in this runtime
    private static var __idRegistry = Set<ID>()
    
    /// Controls access to ID registration
    static let registrationQueue = DispatchQueue(label: "ID Registration", qos: .userInteractive)
    
    /// Backing storage for ``nextAvailableIdRawValue``. Do not access this outside the ``nextIdExclusiveAccessQueue``
    private static var __nextAvailableIdRawValue = ID.min
    
    /// Keeps track of the mimimum ID which is not yet used
    static var nextAvailableIdRawValue: ID {
        get { nextIdExclusiveAccessQueue.sync { __nextAvailableIdRawValue } }
        set { nextIdExclusiveAccessQueue.sync { __nextAvailableIdRawValue = newValue } }
    }
    
    /// Controls access to the next ID which will be generated
    static let nextIdExclusiveAccessQueue = DispatchQueue(label: "Access to next ID", qos: .userInteractive)
    
    
    /// Determines whether an ID has been registered which has the given value
    ///
    ///
    /// - Parameter value: The raw value of some ID
    /// - Returns: `true` iff the given value has been registered
    static func isRegistered(idWithValue value: ID) -> Bool {
        registrationQueue.sync { __idRegistry.contains(value) }
    }
    
    
    /// Registers the given ID as one which currently exists. This is useful for loading existing data.
    ///
    /// After registration, unless recycled, the given ID will not be returned from ``.next()``
    ///
    /// - Parameter id: The ID which already exists but was not created by ``next()`` in this runtime
    static func register(id: Self) {
        registrationQueue.sync {
            __idRegistry.insert(id.rawValue)
            
            nextIdExclusiveAccessQueue.async {
                if id.rawValue == __nextAvailableIdRawValue {
                    __nextAvailableIdRawValue += 1
                }
                
                if isRegistered(idWithValue: __nextAvailableIdRawValue) {
                    __nextAvailableIdRawValue = (__nextAvailableIdRawValue+1 ... ID.max)
                        .first { !isRegistered(idWithValue: $0) }
                        ?? .max
                }
            }
        }
    }
}



// MARK: - API

public extension AppUniqueIdentifier {
    
    /// Finds, registers, and returns the next available ID which is not the same as any currently-existing IDs
    static func next() -> Self {
        Self(id: nextAvailableIdRawValue)
    }
    
    
    /// Notes that the given ID can be put back into the pool of available IDs to be used for something else
    /// - Parameter id: The ID which already exists, which can now be used for some other purpose
    static func recycle(id: Self) {
        registrationQueue.sync {
            __idRegistry.remove(id.rawValue)
            
            nextIdExclusiveAccessQueue.async {
                if id.rawValue < __nextAvailableIdRawValue {
                    __nextAvailableIdRawValue = id.rawValue
                }
            }
        }
    }
    
    
    /// Immediately deletes all registered IDs. The subsequent call to ``next()`` will result in the first ID being returned again.
    ///
    /// You probably shouldn't use this, but it's provided just in case you do
    static func __deleteAllRegisteredIds() {
        registrationQueue.sync {
            nextIdExclusiveAccessQueue.sync {
                __idRegistry = []
                __nextAvailableIdRawValue = .min
            }
        }
    }
}



// MARK: - Conformance

extension AppUniqueIdentifier: Decodable {
    public init(from decoder: Decoder) throws {
        self.init(id: try decoder.singleValueContainer().decode(ID.self))
    }
}



extension AppUniqueIdentifier: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}



extension AppUniqueIdentifier: LosslessStringConvertible {
    
    public init?(_ description: String) {
        guard let id = ID(description) else {
            return nil
        }
        
        self.init(id: id)
    }
    
    public var description: String {
        rawValue.description
    }
}



extension AppUniqueIdentifier: Identifiable {
    
    @inline(__always)
    public var id: ID { rawValue }
    
    
    
    public typealias ID = UInt
}



extension AppUniqueIdentifier: Hashable {}



extension AppUniqueIdentifier: Comparable {
    public static func < (lhs: AppUniqueIdentifier, rhs: AppUniqueIdentifier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
