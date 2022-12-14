import BSONDecoding
import MongoChannel
import MongoWire
import NIOCore

extension Mongo
{
    @frozen public
    struct Reply
    {
        @usableFromInline
        let result:Result<BSON.Dictionary<ByteBufferView>, MongoChannel.ServerError>

        @usableFromInline
        let operationTime:Instant?
        @usableFromInline
        let clusterTime:ClusterTime.Sample?

        init(result:Result<BSON.Dictionary<ByteBufferView>, MongoChannel.ServerError>,
            operationTime:Instant?,
            clusterTime:ClusterTime.Sample?)
        {
            self.result = result
            self.operationTime = operationTime
            self.clusterTime = clusterTime
        }
    }
}
extension Mongo.Reply
{
    public
    init(message:MongoWire.Message<ByteBufferView>) throws
    {
        let dictionary:BSON.Dictionary<ByteBufferView> = try .init(
            fields: try message.sections.body.parse())
        let status:MongoChannel.Status = try dictionary["ok"].decode(
            to: MongoChannel.Status.self)

        let operationTime:Mongo.Instant? = try dictionary["operationTime"]?.decode(
            to: Mongo.Instant.self)
        let clusterTime:Mongo.ClusterTime.Sample? = try dictionary["$clusterTime"]?.decode(
            to: Mongo.ClusterTime.Sample.self)
        
        if  status.ok
        {
            self.init(result: .success(dictionary),
                operationTime: operationTime,
                clusterTime: clusterTime)
        }
        else
        {
            self.init(result: .failure(.init(
                    message: try dictionary["errmsg"]?.decode(to: String.self) ?? "",
                    code: try dictionary["code"]?.decode(to: Int32.self))),
                operationTime: operationTime,
                clusterTime: clusterTime)
        }
    }
}
