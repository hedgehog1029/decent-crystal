module Decent
    class Emote
        def initialize(@shortname : String, @url : String)
        end

        getter shortname, url

        def self.retrieve(db : DB::Database, shortname : String)
            name, url = db.query_one "select * from emotes where shortname=?", shortname, as: {String, String}
            new name, url
        end

        def self.create(db : DB::Database, shortname : String, url : String)
            db.exec "insert into emotes values (?, ?)", shortname, url
            new shortname, url
        end

        def delete(db : DB::Database)
            db.exec "delete from emotes where shortcode=?", @shortname
        end

        def to_json(builder : JSON::Builder)
            builder.object do
                builder.field "shortcode", @shortname
                builder.field "imageURL", @url
            end
        end
    end
end

get "/api/emotes" do |ctx|
    emotes = [] of Decent::Emote

    ctx.db.query "select * from emotes" do |rs|
        rs.each do
            name, url = rs.read(String, String)
            emotes << Decent::Emote.new(name, url)
        end
    end

    {emotes: emotes}.to_json
end

post "/api/emotes" do |ctx|
    session = ctx.ensure_session
    session.ensure_admin

    name = ctx.params.json["shortcode"].as(String)
    url = ctx.params.json["imageURL"].as(String)

    if name.nil? || url.nil?
        missing = {name: name.nil?, url: url.nil?}
        raise Decent::IncompleteParametersException.new("Missing parameters.", missing)
    end

    Decent::Emote.create(ctx.db, name, url)
    Decent.empty_json
rescue DB::Error
    raise Decent::NameAlreadyTakenException.new("That emoji shortcode is already taken.")
end

get "/api/emotes/:shortcode" do |ctx|
    shortcode = ctx.params.url["shortcode"].as(String)
    emote = Decent::Emote.retrieve ctx.db, shortcode

    ctx.response.status_code = 302
    ctx.response.headers["Location"] = emote.url
    next ""
end

delete "/api/emotes/:shortcode" do |ctx|
    session = ctx.ensure_session
    session.ensure_admin
    shortcode = ctx.params.url["shortcode"].as(String)

    ctx.db.exec "delete from emotes where shortcode=?", shortcode
    Decent.empty_json
end
