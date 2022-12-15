import NIOCore

extension Mongo
{
    public
    typealias SessionContext = (id:SessionIdentifier, metadata:SessionMetadata)
}
extension Mongo
{
    @available(*, deprecated, renamed: "SessionPool")
    public
    typealias Cluster = SessionPool

    public final
    actor SessionPool
    {
        private nonisolated
        let monitor:TopologyMonitor

        private
        var released:[SessionIdentifier: SessionMetadata]
        private
        var retained:Set<SessionIdentifier>
        private
        var draining:CheckedContinuation<Void, Never>?

        init(_ monitor:TopologyMonitor) 
        {
            self.monitor = monitor
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
    func with<Session, Success>(_:Session.Type, timeout:Duration = .seconds(10),
        _ body:(inout Session) async throws -> Success) async throws -> Success
        where Session:MongoServerSession
    {
        //  yes, we do need to `await` on the medium before checking out a session,
        //  to avoid generating excessive sessions if a medium is temporarily unavailable
        //  rationale:
        //  https://github.com/mongodb/specifications/blob/master/source/sessions/driver-sessions.rst#why-must-drivers-wait-to-consume-a-server-session-until-after-a-connection-is-checked-out
        let medium:Mongo.SessionMedium = try await self.monitor.medium(Session.medium,
            timeout: timeout)
        let initial:Mongo.SessionContext = await self.checkout(ttl: medium.ttl)

        var session:Session = .init(monitor: self.monitor, context: initial, medium: medium)
        do
        {
            let result:Success = try await body(&session)
            await self.checkin(context: session.context)
            return result
        }
        catch let error
        {
            await self.checkin(context: session.context)
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
    func checkin(context:Mongo.SessionContext)
    {
        guard case _? = self.retained.remove(context.id)
        else
        {
            fatalError("unreachable: released an unknown session! (\(context.id))")
        }
        guard case nil = self.released.updateValue(context.metadata, forKey: context.id)
        else
        {
            fatalError("unreachable: released an duplicate session! (\(context.id))")
        }
        if  self.retained.isEmpty,
            let draining:CheckedContinuation<Void, Never> = self.draining
        {
            draining.resume()
            self.draining = nil
        }
    }
    private
    func checkout(ttl:Mongo.Minutes) -> Mongo.SessionContext
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
    /// Runs a session command against the ``Mongo/Database/.admin`` database,
    /// sending the command to an appropriate cluster member for its type.
    public nonisolated
    func run<Command>(command:Command) async throws -> Command.Response
        where Command:MongoImplicitSessionCommand
    {    
        try await self.with(Mongo.MutableSession.self)
        {
            try await $0.run(command: command)
        }
    }
    /// Runs a session command against the specified database,
    /// sending the command to an appropriate cluster member for its type.
    public nonisolated
    func run<Command>(command:Command, 
        against database:Mongo.Database) async throws -> Command.Response
        where Command:MongoImplicitSessionCommand & MongoDatabaseCommand
    {    
        try await self.with(Mongo.MutableSession.self)
        {
            try await $0.run(command: command, against: database)
        }
    }
}
