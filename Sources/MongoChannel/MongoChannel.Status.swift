import BSONDecoding
import BSONUnions

extension MongoChannel
{
    /// A type that can decode a MongoDB status indicator.
    ///
    /// The following BSON values encode a “success” status (``ok`` is [`true`]()):
    ///
    /// -   [`.bool(true)`](),
    /// -   [`.int32(1)`](),
    /// -   [`.int64(1)`](), and
    /// -   [`.double(1.0)`]().
    ///
    /// The following BSON values encode a “failure” status (``ok`` is [`false`]()):
    ///
    /// -   [`.bool(false)`](),
    /// -   [`.int32(0)`](),
    /// -   [`.int64(0)`](), and
    /// -   [`.double(0.0)`]().
    ///
    /// All other BSON values will produce a decoding error.
    @frozen public
    struct Status:Equatable
    {
        public
        let ok:Bool

        @inlinable public
        init(ok:Bool)
        {
            self.ok = ok
        }
    }
}
extension MongoChannel.Status:BSONDecodable
{
    @inlinable public
    init(bson:AnyBSON<some RandomAccessCollection<UInt8>>) throws
    {
        self.init(ok: try bson.cast
        {
            switch $0
            {
            case .bool(true), .int32(1), .int64(1), .double(1.0):
                return true
            case .bool(false), .int32(0), .int64(0), .double(0.0):
                return false
            default:
                return nil
            }
        })
    }
}
