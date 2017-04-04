import Foundation

/*:
 ## Persisting Structs in Swift
 The purpose of this playground is to demonstrate a simple technique for persisting structs.
 The need for such a technique is motivated by the fact that swift's struct types cannot adopt
 the NSCoding protocol and thus NSKeyedArchiver is not available. Inspiration was provided
 by [The Red Queen Coder](http://redqueencoder.com/property-lists-and-user-defaults-in-swift/) (TL;DR)
 */

/*:
 ## Implementation
 */

/*:
 ### The Encodable Protocol
 Types (such as structs) announce their encodability by adopting the Encodable protocol.
 The encode method is used to store the properties of an instance of the type into a
 dictionary. The initializer is used to reconstruct an instance of the type from that
 dictionary. The initializer is failable because there is no guarantee that the dictionary
 contains the correct properties. The initializer's parameter is optional so as to allow cleaner
 code at the call site. As we will see, it is the dictionaries that are persisted.
 */
public protocol Encodable {
    typealias Properties = Dictionary<String, Any>
    func encode() -> Properties
    init?(_ properties: Properties?)
}

/*:
 ### Helper Extensions on Array
 It will often occur that we have a array of objects to be encoded.
 These extensions will make the usage at the call site a bit cleaner.
 */
extension Array where Element : Encodable {
    public func encode() -> [Encodable.Properties] {
        return map{ $0.encode() }
    }
}

extension Array where Element == Encodable.Properties {
    public func decode<T:Encodable>(type: T.Type) -> [T] {
        return flatMap{ T($0) }
    }
}

/*:
 ### Persistence With User Defaults
 These top level functions will save/load arrays of Encodable objects to/from User Defaults.
 */
public func saveToUserDefaults<T:Encodable>(_ objects: [T], withKey key: String) {
    UserDefaults.standard.set(objects.encode(), forKey: key)
}

public func loadFromUserDefaults<T:Encodable>(type: T.Type, withKey key: String) -> [T]? {
    return (UserDefaults.standard.array(forKey: key) as? [Encodable.Properties])?.decode(type: T.self)
}

/*:
 ### Persistence With Files
 These top level functions will save/load arrays of Encodable objects to/from a file in the document directory.
 */
private func getUrl(forName: String) -> URL {
    return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(forName)
}

public func saveToFile<T:Encodable>(_ values: [T], withName name: String) -> Bool {
    do {
        let data = NSKeyedArchiver.archivedData(withRootObject: values.encode())
        try data.write(to: getUrl(forName: name), options: .atomic)
        return true
    } catch {
        print(error)
    }
    return false
}

public func loadFromFile<T:Encodable>(type: T.Type, withName name: String) -> [T]? {
    do {
        let data = try Data(contentsOf: getUrl(forName: name))
        if let encoded = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Encodable.Properties] {
            return encoded.decode(type: type)
        }
    } catch {
        print(error)
    }
    return nil
}


/*:
 ## An Example of an Encodable Type
 */
/*:
 ### The Encodable Type
 */
struct MyData {
    let int: Int
    let double: Double
    let string: String
    let bool: Bool
    let date: Date
    let blob: Data
}

extension MyData: Encodable {
    
    func encode() -> Properties {
        return ["int": int, "double": double, "string": string, "bool": bool, "date": date, "blob": blob, ]
    }
    
    init?(_ properties: Properties?) {
        guard let properties = properties else { return nil }
        
        if let int = properties["int"] as? Int,
           let double = properties["double"] as? Double,
           let string = properties["string"] as? String,
           let bool = properties["bool"] as? Bool,
           let date = properties["date"] as? Date,
           let blob = properties["blob"] as? Data {
                self.int = int
                self.double = double
                self.string = string
                self.bool = bool
                self.date = date
                self.blob = blob
        } else {
            return nil
        }
    }
}

/*:
 ### Usage
 */
let myData = [MyData(int: 1, double: 1.0, string: "One", bool: true, date: Date(), blob: Data(bytes: [1,2,3,4,5,6,7,8])),
              MyData(int: 2, double: 2.0, string: "Two", bool: false, date: Date(), blob: Data(bytes: [9,10,11,12]))]

print("Original:")
myData.forEach{ print("\t", $0) }

print("\nEncode => Decode:")
myData.encode().decode(type: MyData.self).forEach{ print("\t", $0) }

print("\nUser Defaults: Save => Load")
let key = "MyData"
saveToUserDefaults(myData, withKey: key)
loadFromUserDefaults(type: MyData.self, withKey: key)?.forEach{ print("\t", $0) }

print("\nFile: Save => Load")
let fileName = "MyData.dat"
if saveToFile(myData, withName: fileName) {
    loadFromFile(type: MyData.self, withName: fileName)?.forEach{ print("\t", $0) }
}
else {
    print("Cannot save to \(fileName)")
}
