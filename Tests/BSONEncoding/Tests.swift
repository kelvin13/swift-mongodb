import BSONEncoding
import BSONUnions
import Testing

extension Tests
{
    mutating
    func test(name:String,
        encoded:BSON.Fields,
        literal:BSON.Document<[UInt8]>)
    {
        let encoded:BSON.Document<[UInt8]> = .init(encoded)
        self.group(name)
        {
            $0.assert(encoded ==? literal, name: "binary-equivalence")

            let encoded:[(key:String, value:AnyBSON<ArraySlice<UInt8>>)]? = 
                $0.test(name: "parse-encoded") { _ in try encoded.parse() }
            let literal:[(key:String, value:AnyBSON<ArraySlice<UInt8>>)]? = 
                $0.test(name: "parse-literal") { _ in try literal.parse() }
            
            guard   let encoded:[(key:String, value:AnyBSON<ArraySlice<UInt8>>)],
                    let literal:[(key:String, value:AnyBSON<ArraySlice<UInt8>>)]
            else
            {
                return
            }

            $0.assert(encoded.map(\.key)   ..? literal.map(\.key),   name: "keys")
            $0.assert(encoded.map(\.value) ..? literal.map(\.value), name: "values")
        }
    }
}
