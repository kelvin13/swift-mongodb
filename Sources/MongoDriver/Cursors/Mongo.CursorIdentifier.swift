import BSONSchema

extension Mongo
{
    /// A cursor handle that is guaranteed to be non-null.
    @frozen public
    struct CursorIdentifier:RawRepresentable, Hashable, Sendable
    {
        public
        let rawValue:Int64

        @inlinable public
        init?(rawValue:Int64)
        {
            if  rawValue != 0
            {
                self.rawValue = rawValue
            }
            else
            {
                return nil
            }
        }
    }
}
extension Mongo.CursorIdentifier:BSONScheme
{
}
