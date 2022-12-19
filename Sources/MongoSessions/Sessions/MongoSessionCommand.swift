/// A type that can encode a MongoDB command that can be run
/// as part of a mutable session.
public
protocol MongoSessionCommand<Response>:MongoCommand
{
}