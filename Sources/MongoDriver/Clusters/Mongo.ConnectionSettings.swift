import NIOSSL

extension Mongo
{
    @frozen public
    struct ConnectionSettings:Sendable
    {
        // public
        // let heartbeat:Milliseconds
        public
        let timeout:Milliseconds
        public
        let tls:TLS?

        @inlinable public
        init(timeout:Milliseconds = .seconds(15), tls:TLS? = nil)
        {
            // self.heartbeat = .milliseconds(1000)
            self.timeout = timeout
            self.tls = tls
        }
    }
}
// extension Mongo.ConnectionSettings
// {
//     public
//     init(_ string:Mongo.ConnectionString)
//     {
//         let credentials:Mongo.Credentials? = string.user.map
//         {
//             .init(
//                 authentication: string.authMechanism, 
//                 username: $0.name, 
//                 password: $0.password,
//                 database: string.authSource ?? string.defaultauthdb ?? .admin)
//         }
//         let tls:TLS? = string.tlsCAFile.map(TLS.init(certificatePath:))
//         self.init(credentials: credentials, tls: tls)
//     }
// }
extension Mongo.ConnectionSettings
{
    public
    struct TLS:Sendable
    {
        // TODO: cache certificate loading
        let certificatePath:String
        //let CaCertificate:NIOSSLCertificate?
    }
}
