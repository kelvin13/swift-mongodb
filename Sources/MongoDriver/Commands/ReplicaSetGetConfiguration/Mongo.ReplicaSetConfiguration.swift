import BSONSchema

extension Mongo
{
    public
    struct ReplicaSetConfiguration:Equatable, Sendable
    {
        public
        let name:String
        public
        let writeConcernMajorityJournalDefault:Bool
        public
        let members:[Member]
        public
        let version:Int
        public
        let term:Int

        public
        init(name:String,
            writeConcernMajorityJournalDefault:Bool = true,
            members:[Member],
            version:Int,
            term:Int)
        {
            self.name = name
            self.writeConcernMajorityJournalDefault = writeConcernMajorityJournalDefault
            self.members = members
            self.version = version
            self.term = term
        }
    }
}
extension Mongo.ReplicaSetConfiguration:BSONDictionaryDecodable
{
    @inlinable public
    init(bson:BSON.Dictionary<some RandomAccessCollection<UInt8>>) throws
    {
        self.init(name: try bson["_id"].decode(to: String.self),
            writeConcernMajorityJournalDefault:
                try bson["writeConcernMajorityJournalDefault"]?.decode(to: Bool.self) ?? true,
            members: try bson["members"].decode(to: [Member].self),
            version: try bson["version"].decode(to: Int.self),
            term: try bson["term"].decode(to: Int.self))
    }
}
extension Mongo.ReplicaSetConfiguration:BSONDocumentEncodable
{
    public
    func encode(to bson:inout BSON.Fields)
    {
        bson["_id"] = self.name
        bson["writeConcernMajorityJournalDefault"] = self.writeConcernMajorityJournalDefault
        bson["members"] = self.members
        bson["version"] = self.version
        bson["term"] = self.term
    }
}
