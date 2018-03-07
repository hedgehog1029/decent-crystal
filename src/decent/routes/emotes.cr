module Decent
    class Emote
        def initialize(@shortname : String, @url : String)
        end

        getter shortname, url

        def self.retrieve(shortname : String)
            name, url = db.query_one "select * from emotes where shortname=?", shortname, as: {String, String}
            new name, url
        end

        def self.create(shortname : String, url : String)
            db.exec "insert into emotes values (?, ?)", shortname, url
            new shortname, url
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
    emotes = [] of Emote

    db.query "select * from emotes" do |rs|
        rs.each do
            name, url = rs.read(String, String)
            emotes << Emote.new(name, url)
        end
    end

    {emotes: emotes}.to_json
end

post "/api/emotes" do |ctx|
    session = sessions.ensure(ctx)
    session.ensure_admin

    name = ctx.params.json["shortcode"].as(String)
    url = ctx.params.json["imageURL"].as(String)

    if name.nil? || url.nil?
        missing = {"name" if name.nil?, "url" if url.nil?}
        raise Decent::IncompleteParametersException.new("Missing parameters.", missing)
    end

    Emote.create(name, url)
    {}.to_json
rescue DB::Error
    raise Decent::NameAlreadyTakenException.new("That emoji shortname is already taken.")
end

get "/api/emotes/:shortcode" do |ctx|
    shortcode = ctx.params.url["shortcode"].as(String)
    emote = Emote.retrieve shortcode

    ctx.response.status_code = 302
    ctx.headers["Location"] = emote.url
    next ""
end

delete "/api/emotes/:shortcode" do |ctx|
    session = sessions.ensure(ctx)
    session.ensure_admin
    shortcode = ctx.params.url["shortcode"].as(String)

    db.exec "delete from emotes where shortcode=?", shortcode
    {}.to_json
end
