extension Mongo.Session
{
    @usableFromInline final
    class State
    {
        @usableFromInline
        var lastOperationTime:Mongo.Instant?
        @usableFromInline
        var metadata:Mongo.SessionMetadata

        init(_ metadata:Mongo.SessionMetadata)
        {
            self.lastOperationTime = nil
            self.metadata = metadata
        }
    }
}
extension Mongo.Session.State
{
    @usableFromInline
    func update(touched:ContinuousClock.Instant,
        operationTime:Mongo.Instant?)
    {
        self.metadata.touched = touched
        self.lastOperationTime = operationTime
    }
}
