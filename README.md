# `AppUniqueIdentifier`


An AUID is an identifier which is unique to a runtime andor save data. While UUID is good for general use, this is good specifically for a single session.

The philosophy behind this comes from a desire to have a unique identifier assigned to various objects, but use as little data as possible when serialized. In fact, this was invented for [Rent Split](https://split.rent), a webapp which stored no data at all server-side, so the share URLs contained the entire app state; that's why the IDs needed to be as short as possible.

This is only guaranteed to be unique per-session if used correctly. Any further uniqueness is not guaranteed. You might think of these as Instance-Unique Identifiers if that helps.

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

AUIDs are currently encoded as simple integers. One can expect the above `Person` instance to be encoded like this:

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


The act of decoding an AUID automatically assures that the ID is not used in any future calls to `.next()`. Encoding an AUID, though, has no special behavior.



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



# Regions

Since version 1.1, App-Unique Identifiers are arranged into four groups, called "Regions":

1. ✅ **General-use** – A large amount of IDs which can be generated and registered. Though finite, it is a large enough range that client-side applications should not exceed its limit if using these APIs correctly. **If your application is using enough IDs that this is too few, then this is not the package for you. I recommend using UUIDs insted.** But seriously, if you use up all these IDs, that's Exbibytes of data; don't worry about it.
2. 🔒 **Unused** – A large amount of IDs which have not been allocated for any use. These cannot be used in any way. Future versions of AUID might introduce usage of these. This blockage is to allow future changes to be nondestructive and backwards-compatible
3. *️⃣ **Private-Use** – A small amount of IDs which are manually and specifically requested. Like the Unicode private-use plane, this region of IDs has no specific intent/meaning, and allows the developer to ascribe specific meanings to each. The small size of this range means that there are no requests to generate a "next" one, and each specific one should be carefully chosen by the developer.
4. ❗️ **Error** – A single ID which signifies that an error has occurred

For a sense of how these are laid out, here's a not-to-scale diagram:

```
✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒
🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒
🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒
🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒 🔒
🔒 🔒 🔒 🔒 🔒 🔒 🔒 *️⃣ *️⃣ ❗️
```


This package comes with various APIs regarding these regions.
