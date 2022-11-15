# `AppUniqueIdentifier`


An AUID is an identifier which is unique to a runtime andor save data. While UUID is good for general use, this is good specifically for a single session.

This is only guaranteed to be unique per-session if used correctly. Any further uniqueness is not guaranteed.

The current implementation simply uses positive integers. However, it's good practice to treat this as an opaque type in case the implementation changes in the future.



## Creating a new ID

To create a new ID, you must call `.next()`, for a new ID to be generated and returned:

```swift
struct Person: Identifiable, Codable {
    var id: AppUniqueIdentifier = .next()
    let name: String
}


let person = Person(name: "Dax")
```



## Encoding & Decoding an ID

AUIDs are encoded as simple integers. One can expect the above `Person` instance to be encoded like this:

```json
{
    "id": 7,
    "name": "Dax"
}
```


AUID has built-in encoding and decoding, so nothing special need be done. Just use any Swift encoder/decoder, like this:

```swift
let jsonData = try JSONEncoder().encode(person)
let decodedPerson = try JSONDecoder().decode(Person.self, from: jsonData)
assert(person == decodedPerson)
```


Decoding an AUID assures that the ID is not used in any future calls to `.next()`. Encoding an AUID has no special behavior.



## Stringification

To create a string form of a given ID, simply call `.description`, or pass it to `String(describing:)`:

```swift
Text(verbatim: person.id.description)
```


If you have a string form of an ID already (e.g. one you got from calling `.description`), you may transform it back into an `AppUniqueIdentifier` with the `.init(_:)` initializer. Only valid ID strings will result in a new value; invalid ones result in `nil`. The subsystem will ensure that this ID is not returned by `.next()`



## When you're done with an ID

If you no longer wish to use an ID (for example, the concept it was tracking has been deleted by the user), then you may pass it to `AppUniqueIdentifier.recycle(id:)`:

```swift
mutating func remove(_ person: Person) {
    self.people.remove(person)
    AppUniqueIdentifier.recycle(id: person.id)
}
```
