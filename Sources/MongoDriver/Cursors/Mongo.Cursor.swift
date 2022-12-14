import BSONDecoding

extension Mongo
{
    @frozen public
    struct Cursor<Element>:Sendable
        where Element:BSONDocumentDecodable & Sendable
    {
        public
        let namespace:Namespaced<Collection>
        public
        let elements:[Element]
        public
        let handle:Int64

        @inlinable public
        init(namespace:Namespaced<Collection>, elements:[Element], handle:Int64)
        {
            self.namespace = namespace
            self.elements = elements
            self.handle = handle
        }
    }
}
extension Mongo.Cursor:Equatable where Element:Equatable
{
}
extension Mongo.Cursor:BSONDictionaryDecodable
{
    @inlinable public
    init<Bytes>(bson:BSON.Dictionary<Bytes>) throws
    {
        self = try bson["cursor"].decode(as: BSON.Dictionary<Bytes.SubSequence>.self)
        {
            .init(namespace: try $0["ns"].decode(to: Mongo.Namespaced<Mongo.Collection>.self),
                elements: try ($0["firstBatch"] ?? $0["nextBatch"]).decode(to: [Element].self),
                handle: try $0["id"].decode(to: Int64.self))
        }
    }
}
