class Emote < Crecto::Model
    include Crecto::Schema

    schema "emotes" do
        field :shortcode, String, primary_key: true
        field :url, String
    end

    def to_json(builder : JSON::Builder)
        builder.object do
            builder.field "shortcode", @shortcode
            builder.field "imageURL", @url
        end
    end
end

get "/api/emotes" do |ctx|
    emotes = Repo.all(Emote)

    {emotes: emotes}.to_json
end

post "/api/emotes" do |ctx|
    session = ctx.ensure_session
    session.ensure_admin

    name = ctx.params.json["shortcode"]?.assert_string
    url = ctx.params.json["imageURL"]?.assert_string

    emote = Emote.new
    emote.shortcode = name
    emote.url = url
    changes = Repo.insert(emote)

    raise Decent::InvalidParameterException.new("Invalid emote payload!") unless changes.valid?

    Decent.empty_json
end

get "/api/emotes/:shortcode" do |ctx|
    shortcode = ctx.params.url["shortcode"]?.assert_string
    emote = Repo.get(Emote, shortcode)
    raise Decent::NotFoundException.new("Emote not found.") if emote.nil?

    ctx.response.status_code = 302
    ctx.response.headers["Location"] = emote.url.as(String)
    next ""
end

delete "/api/emotes/:shortcode" do |ctx|
    session = ctx.ensure_session
    session.ensure_admin

    shortcode = ctx.params.url["shortcode"]?.assert_string
    emote = Repo.get(Emote, shortcode)
    Repo.delete(emote) unless emote.nil?

    Decent.empty_json
end
