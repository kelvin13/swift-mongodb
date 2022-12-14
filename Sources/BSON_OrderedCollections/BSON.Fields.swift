import BSONEncoding
import OrderedCollections

extension BSON.Fields
{
    @inlinable public
    subscript<Encodable>(key:String, elide elide:Bool) -> OrderedDictionary<String, Encodable>?
        where Encodable:BSONEncodable
    {
        get
        {
            nil
        }
        set(value)
        {
            if let value:OrderedDictionary<String, Encodable>, !(elide && value.isEmpty)
            {
                self.append(key: key, with: value.encode(to:))
            }
        }
    }
}
