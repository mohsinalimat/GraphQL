import Runtime

enum RuntimeReflectionError: Error {
    case requiredValueMissing(key: String)
}

extension MapInitializable {
    public init(map: Map) throws {
        guard case .dictionary(let dictionary) = map else {
            throw MapError.cannotInitialize(type: Self.self, from: try type(of: map.get()))
        }
        
        self = try createInstance()
        let info = try typeInfo(of: Self.self)
        
        for property in info.properties {
            guard let initializable = property.type as? MapInitializable.Type else {
                throw MapError.notMapInitializable(property.type)
            }
            switch dictionary[property.name] ?? .null {
            case .null:
                guard let expressibleByNilLiteral = property.type as? ExpressibleByNilLiteral.Type else {
                    throw RuntimeReflectionError.requiredValueMissing(key: property.name)
                }
                try property.set(value: expressibleByNilLiteral.init(nilLiteral: ()), on: &self)
            case let x:
                try property.set(value: initializable.init(map: x), on: &self)
            }
        }
    }
}

extension Map : MapInitializable {
    public init(map: Map) throws {
        self = map
    }
}

extension Bool : MapInitializable {
    public init(map: Map) throws {
        guard case .bool(let bool) = map else {
            throw MapError.cannotInitialize(type: Bool.self, from: try type(of: map.get()))
        }
        self = bool
    }
}

extension Double : MapInitializable {
    public init(map: Map) throws {
        guard case .double(let double) = map else {
            throw MapError.cannotInitialize(type: Double.self, from: try type(of: map.get()))
        }
        self = double
    }
}

extension Int : MapInitializable {
    public init(map: Map) throws {
        guard case .int(let int) = map else {
            throw MapError.cannotInitialize(type: Int.self, from: try type(of: map.get()))
        }
        self = int
    }
}

extension String : MapInitializable {
    public init(map: Map) throws {
        guard case .string(let string) = map else {
            throw MapError.cannotInitialize(type: String.self, from: try type(of: map.get()))
        }
        self = string
    }
}

extension Optional : MapInitializable {
    public init(map: Map) throws {
        guard let initializable = Wrapped.self as? MapInitializable.Type else {
            throw MapError.notMapInitializable(Wrapped.self)
        }
        if case .null = map {
            self = .none
        } else {
            self = try initializable.init(map: map) as? Wrapped
        }
    }
}

extension Array : MapInitializable {
    public init(map: Map) throws {
        guard case .array(let array) = map else {
            throw MapError.cannotInitialize(type: Array.self, from: try type(of: map.get()))
        }
        guard let initializable = Element.self as? MapInitializable.Type else {
            throw MapError.notMapInitializable(Element.self)
        }
        var this = Array()
        this.reserveCapacity(array.count)
        for element in array {
            if let value = try initializable.init(map: element) as? Element {
                this.append(value)
            }
        }
        self = this
    }
}

public protocol MapDictionaryKeyInitializable {
    init(mapDictionaryKey: String)
}

extension String : MapDictionaryKeyInitializable {
    public init(mapDictionaryKey: String) {
        self = mapDictionaryKey
    }
}

extension Dictionary : MapInitializable {
    public init(map: Map) throws {
        guard case .dictionary(let dictionary) = map else {
            throw MapError.cannotInitialize(type: Dictionary.self, from: try type(of: map.get()))
        }
        guard let keyInitializable = Key.self as? MapDictionaryKeyInitializable.Type else {
            throw MapError.notMapDictionaryKeyInitializable(type(of: self))
        }
        guard let valueInitializable = Value.self as? MapInitializable.Type else {
            throw MapError.notMapInitializable(Element.self)
        }
        var this = Dictionary(minimumCapacity: dictionary.count)
        for (key, value) in dictionary {
            if let key = keyInitializable.init(mapDictionaryKey: key) as? Key {
                this[key] = try valueInitializable.init(map: value) as? Value
            }
        }
        self = this
    }
}
