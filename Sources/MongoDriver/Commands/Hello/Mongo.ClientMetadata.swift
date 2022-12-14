import BSONEncoding

extension Mongo
{
    struct ClientMetadata
    {
        let appname:String?

        init(appname:String?)
        {
            self.appname = appname
        }
    }
}
extension Mongo.ClientMetadata:BSONDocumentEncodable
{
    private static
    var os:String
    {
        #if os(Linux)
        "Linux"
        #elseif os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        "Darwin"
        #elseif os(Windows)
        "Windows"
        #else
        "unknown"
        #endif
    }

    func encode(to bson:inout BSON.Fields)
    {
        if let appname:String = self.appname
        {
            bson["application"] = .init
            {
                $0["name"] = appname
            }
        }
        bson["driver"] = .init
        {
            $0["name"] = "swift-mongodb"
            $0["version"] = "0"
        }
        bson["os"] = .init
        {
            $0["type"] = Self.os
        }
    }
}
