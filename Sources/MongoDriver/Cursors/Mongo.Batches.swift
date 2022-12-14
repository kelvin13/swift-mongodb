import BSONDecoding
import Durations
import MongoSchema

extension Mongo
{
    @frozen public
    struct Batches<BatchElement> where BatchElement:MongoDecodable
    {
        public
        let selection:Mongo.Selection,
            session:Mongo.Session
        public
        let current:Current
        /// The database and collection this batch sequence is drawn from.
        public
        let namespace:Namespaced<Collection>
        /// The timeout used for ``GetMore`` operations from this batch sequence.
        /// This will be [`nil`]() for non-tailable cursors.
        public
        let timeout:Milliseconds?
        /// The maximum size of each batch retrieved by this batch sequence.
        public
        let stride:Int

        @usableFromInline
        init(selection:Mongo.Selection, session:Mongo.Session,
            initial:Cursor<BatchElement>,
            timeout:Milliseconds?,
            stride:Int)
        {
            self.selection = selection
            self.session = session

            self.current = .init(elements: initial.elements, handle: initial.handle)

            self.namespace = initial.namespace
            self.timeout = timeout
            self.stride = stride
        }
    }
}
extension Mongo.Batches
{
    @inlinable public
    var database:Mongo.Database
    {
        self.namespace.database
    }
    @inlinable public
    var collection:Mongo.Collection
    {
        self.namespace.collection
    }
}
extension Mongo.Batches:AsyncSequence, AsyncIteratorProtocol
{
    public
    typealias Element = [BatchElement]

    @inlinable public
    func makeAsyncIterator() -> Self
    {
        self
    }
    @inlinable public
    func next() async throws -> [BatchElement]?
    {
        guard self.current.elements.isEmpty
        else
        {
            return self.current.move()
        }
        guard let next:Mongo.CursorIdentifier = self.current.next
        else
        {
            return nil
        }

        let cursor:Mongo.Cursor<BatchElement> = try await self.session.run(
            command: Mongo.GetMore<BatchElement>.init(cursor: next,
                collection: self.collection,
                timeout: self.timeout,
                count: self.stride),
            against: self.database,
            on: self.selection)
        
        self.current.handle = cursor.handle

        if  cursor.elements.isEmpty, case nil = self.current.next
        {
            return nil
        }
        else
        {
            return cursor.elements
        }
    }
}
extension Mongo.Batches
{
    public
    func `deinit`() async throws
    {
        if  let cursor:Mongo.CursorIdentifier = self.current.next
        {
            let _:Mongo.KillCursorsResponse = try await self.session.run(
                command: Mongo.KillCursors.init([cursor], collection: self.collection),
                against: self.database,
                on: self.selection)
        }
    }
}
