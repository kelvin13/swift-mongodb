import Durations

extension Mongo
{
    public final
    actor SessionPool
    {
        private nonisolated
        let cluster:Cluster

        private
        var released:[SessionIdentifier: SessionMetadata]
        private
        var retained:Set<SessionIdentifier>
        private
        var draining:CheckedContinuation<Void, Never>?

        init(cluster:Cluster) 
        {
            self.cluster = cluster

            self.released = [:]
            self.retained = []
            self.draining = nil
        }

        deinit
        {
            guard   self.retained.isEmpty,
                    self.released.isEmpty
            else
            {
                fatalError("unreachable (deinit while session pool still contains sessions)")
            }
            guard case nil = self.draining
            else
            {
                fatalError("unreachable (deinit while session pool is still being drained)")
            }
        }
    }
}
extension Mongo.SessionPool
{
    public nonisolated
    func withSession<Success>(connectionTimeout:Duration = .seconds(10),
        _ body:(Mongo.Session) async throws -> Success) async throws -> Success
    {
        try await self.withSessionMetadata(connectionTimeout: connectionTimeout)
        {
            (id:Mongo.SessionIdentifier, metadata:inout Mongo.SessionMetadata) in

            let session:Mongo.Session = .init(on: self.cluster,
                connectionTimeout: connectionTimeout,
                metadata: metadata,
                id: id)
            defer
            {
                metadata = session.state.metadata
            }
            return try await body(session)
        }
    }
    public nonisolated
    func withSessionMetadata<Success>(connectionTimeout:Duration,
        _ body:(Mongo.SessionIdentifier, inout Mongo.SessionMetadata) async throws -> Success)
        async throws -> Success
    {
        //  TODO: avoid generating excessive sessions if a medium is temporarily unavailable
        //  rationale:
        //  https://github.com/mongodb/specifications/blob/master/source/sessions/driver-sessions.rst#why-must-drivers-wait-to-consume-a-server-session-until-after-a-connection-is-checked-out
        //  TODO: above only applies for IMPLICIT sessions

        let sessions:Mongo.LogicalSessions = try await self.cluster.sessions(
            by: .now.advanced(by: connectionTimeout))
        
        var metadata:Mongo.SessionMetadata
        let id:Mongo.SessionIdentifier

        (id, metadata) = await self.checkout(ttl: sessions.ttl)

        do
        {
            let result:Success = try await body(id, &metadata)
            await self.checkin(id: id, metadata: metadata)
            return result
        }
        catch let error
        {
            await self.checkin(id: id, metadata: metadata)
            throw error
        }
    }
}
extension Mongo.SessionPool
{
    func drain() async -> [Mongo.SessionIdentifier]
    {
        if !self.retained.isEmpty
        {
            guard case nil = self.draining
            else
            {
                fatalError("cannot drain session pool that is already being drained!")
            }
            await withCheckedContinuation
            {
                self.draining = $0
            }
        }
        defer
        {
            self.released = [:]
        }
        return .init(self.released.keys)
    }
    private
    func checkin(id:Mongo.SessionIdentifier, metadata:Mongo.SessionMetadata)
    {
        guard case _? = self.retained.remove(id)
        else
        {
            fatalError("unreachable: released an unknown session! (\(id))")
        }
        guard case nil = self.released.updateValue(metadata, forKey: id)
        else
        {
            fatalError("unreachable: released an duplicate session! (\(id))")
        }
        if  self.retained.isEmpty,
            let draining:CheckedContinuation<Void, Never> = self.draining
        {
            draining.resume()
            self.draining = nil
        }
    }
    private
    func checkout(ttl:Minutes) -> (id:Mongo.SessionIdentifier, metadata:Mongo.SessionMetadata)
    {
        guard case nil = self.draining
        else
        {
            fatalError("unreachable: cannot checkout session while session pool is being drained!")
        }
        let now:ContinuousClock.Instant = .now
        while case let (id, metadata)? = self.released.popFirst()
        {
            if now < metadata.touched.advanced(by: .minutes(ttl - 1))
            {
                self.retained.update(with: id)
                return (id, metadata)
            }
        }
        // very unlikely, but do not generate a session id that we have
        // already generated. this is not foolproof (because we could
        // have persistent sessions from a previous run), but allows us
        // to maintain local dictionary invariants.
        while true
        {
            let id:Mongo.SessionIdentifier = .random()
            if case nil = self.retained.update(with: id)
            {
                return (id, .init(touched: now))
            }
        }
    }
}
extension Mongo.SessionPool
{
    /// Runs a session command against the specified database,
    /// sending the command to an appropriate cluster member for its type.
    @inlinable public nonisolated
    func run<Command>(command:Command, against database:Command.Database,
        on preference:Mongo.ReadPreference = .primary) async throws -> Command.Response
        where Command:MongoImplicitSessionCommand
    {    
        try await self.withSession
        {
            try await $0.run(command: command, against: database, on: preference)
        }
    }
}
