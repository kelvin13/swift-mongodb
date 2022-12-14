import BSONUnions

/// A type that can be (efficiently) decoded from a BSON variant value
/// backed by a preferred type of storage particular to the decoded type.
///
/// This protocol is parallel and unrelated to ``BSONDecodable`` to
/// emphasize the performance characteristics of types that conform to
/// this protocol and not ``BSONDecodable``.
public
protocol BSONDecodableView<Bytes>:Equatable
{
    /// The backing storage used by this type. It is recommended that 
    /// implementations satisfy this with generics.
    associatedtype Bytes:RandomAccessCollection<UInt8>

    /// Attempts to cast a BSON variant backed by ``Bytes`` to an instance
    /// of this view type without copying the contents of the backing storage.
    init(_:AnyBSON<Bytes>) throws
}

extension BSON.Binary:BSONDecodableView
{
}
extension BSON.Document:BSONDecodableView
{
}
extension BSON.Tuple:BSONDecodableView
{
}
extension BSON.UTF8:BSONDecodableView where Bytes:RandomAccessCollection<UInt8>
{
}
