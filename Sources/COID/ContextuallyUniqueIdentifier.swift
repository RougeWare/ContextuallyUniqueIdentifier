//
//  ContextuallyUniqueIdentifier.swift
//
//
//  Created by Ky Leggiero on 2022-07-08.
//

import Foundation

import SimpleLogging



public typealias COID = ContextuallyUniqueIdentifier

@available(*, deprecated, renamed: "COID", message: "In version 1.2.0, AppUniqueIdentifier was renamed to ContextuallyUniqueIdentifier (COID) to clarify its usage")
public typealias AppUniqueIdentifier = COID



/// An identifier which is unique to this app's runtime.
///
/// This is only guaranteed to be unique in this app's runtime. Any further uniqueness is not guaranteed.
///
/// App-Unique Identifiers are arranged into four groups:
/// 1. ✅ **General-use** – A large amount of IDs which can be generated and registered. Though finite, it is a large enough range that most applications should not exceed its limit if using these APIs correctly. **If your application is using enough IDs that this is too few, then this is not the package for you. I recommend using UUIDs insted.** But seriously, if you use up all these IDs, that's Exbibytes of data; don't worry about it.
/// 2. 🔒 **Unused** – A large amount of IDs which have not been allocated for any use. These cannot be used in any way. Future versions of COID might introduce usage of these. This blockage is to allow future changes to be nondestructive and backwards-compatible
/// 3. *️⃣ **Private-Use** – A small amount of IDs which must be manually and specifically requested. Like the Unicode private-use plane, this region of IDs has no specific intent/meaning, and allows the developer to ascribe specific meanings to each. The small size of this range means that there are no requests to generate a "next" one, and each specific one should be carefully chosen by the developer.
/// 4. ❗️ **Error** – A single ID which signifies that an error has occurred
///
/// For a sense of how these are laid out, here's a not-to-scale diagram:
/// ```
/// ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
/// ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
/// ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
/// ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
/// ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
/// 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒
/// 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒
/// 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒
/// 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒
/// 🔒 🔒 🔒 🔒 🔒 🔒 🔒 *️⃣ *️⃣ ❗️
/// ```
public struct ContextuallyUniqueIdentifier {
    private let rawValue: ID
}



// MARK: - Private APIs

// MARK: Initialization

fileprivate extension ContextuallyUniqueIdentifier {
    
    /// Creates a new app-unique ID with the given value. This also registers it immediately, to ensure all app-unique IDs are unique across all others
    ///
    /// - Parameter id: The value of the new app-unique ID
    init(id: ID) {
        self.rawValue = id
        
        Self.register(id: &self)
    }
}


// MARK: Static registry

fileprivate extension ContextuallyUniqueIdentifier {
    
    /// The IDs which are currently in use in this runtime
    private static var __idRegistry = Set<ID>()
    
    /// Controls access to ID registration
    static let registrationQueue = DispatchQueue(label: "ID Registration", qos: .userInteractive)
    
    /// Backing storage for ``nextAvailableIdRawValue``. Do not access this outside the ``nextIdExclusiveAccessQueue``
    private static var __nextAvailableIdRawValue = RegionRanges.generalUse.lowerBound
    
    /// Keeps track of the mimimum ID which is not yet used
    static var nextAvailableIdRawValue: ID {
        get { nextIdExclusiveAccessQueue.sync { __nextAvailableIdRawValue } }
        set { nextIdExclusiveAccessQueue.sync { __nextAvailableIdRawValue = newValue } }
    }
    
    /// Controls access to the next ID which will be generated
    static let nextIdExclusiveAccessQueue = DispatchQueue(label: "Access to next ID", qos: .userInteractive)
    
    
    /// Determines whether an ID has been registered which has the given value
    ///
    /// - Parameter value: The raw value of some ID
    /// - Returns: `true` iff the given value has been registered
    static func isRegistered(idWithValue value: ID) -> Bool {
        registrationQueue.sync { __idRegistry.contains(value) }
    }
    
    
    /// Registers the given ID as one which currently exists. This is useful for loading existing data.
    ///
    /// After registration, unless recycled, the given ID will not be returned from ``.next()``.
    ///
    /// This only registers IDs within the general-use region.
    ///
    /// ### Error States:
    /// - If the given ID is outside that region, then it won't be registered, and the given ID is changed to the error ID. This is why `id` is `inout`.
    /// - If all other IDs are used up, then it will be registered but undefined behavior may occur.
    ///
    /// In both these cases, an assertion failure is thrown for debugging sessions, an error message is logged, and production builds continue running.
    ///
    /// - Parameter id: The ID which already exists but was not created by ``next()`` in this runtime. If it is outside the General-Use region, then it is changed to the error ID before this function returns
    static func register(id: inout Self) {
        registrationQueue.sync {
            
            guard RegionRanges.generalUse.contains(id.rawValue) else {
                let message = "Could not register ID; it would be outside the general-use region: \(id.rawValue)"
                log(error: message)
                assertionFailure(message)
                id = .error
                return
            }
            
            __idRegistry.insert(id.rawValue)
            
            nextIdExclusiveAccessQueue.async { [id] in
                if id.rawValue == __nextAvailableIdRawValue {
                    __nextAvailableIdRawValue += 1
                }
                
                if isRegistered(idWithValue: __nextAvailableIdRawValue) {
                    guard let nextId = (__nextAvailableIdRawValue+1 ..< RegionRanges.generalUse.upperBound)
                        .first(where: { !isRegistered(idWithValue: $0) })
                    else {
                        let message = "ID registry full! No more IDs will be able to be created/registered until some are recycled"
                        log(fatal: message)
                        assertionFailure(message)
                        return
                    }
                    
                    __nextAvailableIdRawValue = nextId
                }
            }
        }
    }
}



// MARK: - API

public extension ContextuallyUniqueIdentifier {
    
    /// Finds, registers, and returns the next available ID which is not the same as any currently-existing IDs.
    ///
    /// This will only return IDs from the Generl Use plane
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
                __nextAvailableIdRawValue = RegionRanges.generalUse.lowerBound
            }
        }
    }
}



// MARK: - Region

/// The various regions of AUIs
///
/// ```
///   All regions     (1.84×10^19)
/// ┌──────────────────────────────┐
/// │ General Use     (9.22×10^18) │
/// │                              │
/// │               0              │
/// │                              │
/// │                              │
/// │              ...             │
/// │                              │
/// │                              │
/// │   9,223,372,036,854,775,806  │
/// ├──────────────────────────────┤
/// │ Unused          (9.22×10^18) │
/// │                              │
/// │   9,223,372,036,854,775,807  │
/// │                              │
/// │                              │
/// │              ...             │
/// │                              │
/// │                              │
/// │  18,446,744,073,709,551,359  │
/// ├──────────────────────────────┤
/// │ Private Use            (256) │
/// │                              │
/// │  18,446,744,073,709,551,360  │
/// │              ...             │
/// │  18,446,744,073,709,551,614  │
/// ├──────────────────────────────┤
/// │ Error Indicator          (1) │
/// │  18,446,744,073,709,551,615  │
/// └──────────────────────────────┘
///
/// ```
private enum RegionRanges {
    static let allPossibleValues: ClosedRange<ID> = .min ... .max
    
    static let generalUse: Range<ID> = .min ..< .max/2
    static let unused: Range<ID> = generalUse.upperBound ..< privateUse.lowerBound
    static let privateUse: Range<ID> = .max-ID(UInt8.max) ..< .max
    
    static let error = ID.max
    
    
    
    typealias ID = COID.ID
}



public extension ContextuallyUniqueIdentifier {
    
    
    /// Returns an identifier from the private use region at the given offset
    ///
    /// App-Unique Identifiers are split into various regions. The "private use" region is designared for uncommon identifiers, whose meaning is left up to the developer using them.
    ///
    /// For example, one way to use a private-use identifier is as a marker for "no selection", when the concept of "no selection" still needs to be identified.
    ///
    /// - Parameter offset: The specific private-use identifier to use. There are 256 private-use identifiers, and they don't have any inherent meaning
    /// - Returns: An app-unique identifier in the private-use region at the given offset
    static func privateUse(offset: UInt8) -> Self {
        Self.init(rawValue: RegionRanges.privateUse.upperBound - .init(offset) - 1)
    }
    
    
    /// The error COID
    ///
    /// This special value is the only one in the error region, and only means that a serious problem occurred (e.g. could not allocate an COID).
    /// This exists to allow objects to still exist while requiring a non-nil COID field, even after a serious problem occurred.
    static let error = Self(rawValue: RegionRanges.error)
    
    
    /// The region this COID belongs to. See the documentation for ``ContextuallyUniqueIdentifier`` for more information
    ///
    /// Each COID belongs to exactly one region, so this is deterministic for any given COID.
    @inline(__always)
    var region: Region {
        Region(of: self)
    }
    
    
    /// Determines whether or not this is the error COID.
    ///
    /// The error COID has no inherent meaning; it just means that a serious problem occurred regarding App-Unique Identifiers
    @inline(__always)
    var isError: Bool {
        self == .error
    }
    
    
    
    /// An COID region. See the documentation for ``ContextuallyUniqueIdentifier`` for more information
    enum Region {
        
        /// The General-Use region. See the documentation for ``ContextuallyUniqueIdentifier`` for more information
        case generalUse
        
        /// The unused region. See the documentation for ``ContextuallyUniqueIdentifier`` for more information
        case unused
        
        /// The Private-Use region. See the documentation for ``ContextuallyUniqueIdentifier`` for more information
        case privateUse
        
        /// The Error region. See the documentation for ``ContextuallyUniqueIdentifier`` for more information
        case error
    }
}



public extension ContextuallyUniqueIdentifier.Region {
    
    /// Determines whether this region contains the given identifier.
    ///
    /// Each COID belongs to exactly one region. So when this returns `true` for one COID, all other regions return `false`
    ///
    /// - Parameter id: Any App-Unique Identifier to check against this range
    ///
    /// - Returns: `true` iff this region contains that ID
    func contains(_ id: ContextuallyUniqueIdentifier) -> Bool {
        range.contains(id.rawValue)
    }
}



extension ContextuallyUniqueIdentifier.Region: CaseIterable {
}



private extension ContextuallyUniqueIdentifier.Region {
    
    init(of id: ContextuallyUniqueIdentifier) {
        self = Self.allCases.first { $0.contains(id) } ?? .error
    }
    
    
    var range: any RangeExpression<ContextuallyUniqueIdentifier.ID> {
        switch self {
        case .generalUse: RegionRanges.generalUse
        case .unused:     RegionRanges.unused
        case .privateUse: RegionRanges.privateUse
        case .error:      RegionRanges.error ... RegionRanges.error
        }
    }
}



// MARK: - Conformance

extension ContextuallyUniqueIdentifier: Decodable {
    public init(from decoder: Decoder) throws {
        self.init(id: try decoder.singleValueContainer().decode(ID.self))
    }
}



extension ContextuallyUniqueIdentifier: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}



extension ContextuallyUniqueIdentifier: LosslessStringConvertible {
    
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



extension ContextuallyUniqueIdentifier: Identifiable {
    
    @inline(__always)
    public var id: ID { rawValue }
    
    
    
    public typealias ID = UInt
}



extension ContextuallyUniqueIdentifier: Hashable {}



extension ContextuallyUniqueIdentifier: Comparable {
    public static func < (lhs: ContextuallyUniqueIdentifier, rhs: ContextuallyUniqueIdentifier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
