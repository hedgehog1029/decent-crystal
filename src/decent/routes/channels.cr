class DChannel < Crecto::Model
    include Crecto::Schema

    schema "channels" do
        field :name, String
        has_many :pins, Message
    end

    validate_required [:name]
    validate_format :name, /^[a-zA-Z-_]+$/

    def to_json(builder : JSON::Builder)
        builder.object do
            builder.field "id", @id
            builder.field "name", @name
        end
    end
end

class Ack < Crecto::Model
    include Crecto::Schema

    schema "acks" do
        field :user_id, PkeyValue, primary_key: true
        field :channel_id, PkeyValue, primary_key: true
        field :ack, PkeyValue
    end
end

get "/api/channels" do |ctx|
    channels = Repo.all(DChannel).as(Array)

    {channels: channels}.to_json
end

post "/api/channels" do |ctx|
    session = ctx.ensure_session
    session.ensure_admin

    name = ctx.params.json["name"]?.assert_string

    ch = DChannel.new
    ch.name = name
    r = Repo.insert(ch)
    raise Decent::InvalidParameterException.new("Invalid parameters") unless r.valid?

    {channelID: r.instance.id}.to_json
end

get "/api/channels/:id" do |ctx|
    session = ctx.sessions.session?(ctx)
    has_session = !session.nil?

    id = ctx.params.url["id"]?.assert_string
    channel = Repo.get(DChannel, id.to_i32)
    assert_found channel, "That channel wasn't found!"

    # TODO: Implement session-specific things
    {channel: channel}.to_json
end

patch "/api/channels/:id" do |ctx|
    session = ctx.ensure_session
    session.ensure_admin

    id = ctx.params.url["id"]?.assert_string
    new_name = ctx.params.json["name"]?.assert_string

    channel = Repo.get(DChannel, id.to_i32)
    assert_found channel, "That channel wasn't found!"

    channel.name = new_name
    Repo.update(channel)

    Decent.empty_json
end

delete "/api/channels/:id" do |ctx|
    session = ctx.ensure_session
    session.ensure_admin

    id = ctx.params.url["id"]?.assert_string
    new_name = ctx.params.json["name"]?.assert_string

    channel = Repo.get(DChannel, id.to_i32)
    assert_found channel, "That channel wasn't found!"
    Repo.delete(channel)

    Decent.empty_json
end

post "/api/channels/:id/mark-read" do |ctx|
    session = ctx.ensure_session

    id = ctx.params.url["id"]?.assert_string.to_i32
    raise Decent::IncompleteParametersException.new("Missing channel ID.", {id: true}) if id.nil?
    last_msg = Repo.get_by(Message, channel_id: id).as(Message?)
    return Decent.empty_json if last_msg.nil?

    ack = Ack.new
    ack.user_id = Repo.get_association(session, :user).id
    ack.channel_id = id
    ack.ack = last_msg.id

    Decent.empty_json
end

get "/api/channels/:id/messages" do |ctx|
    id = ctx.params.url["id"]?.assert_string.to_i32
    before = ctx.params.query["before"]?
    after = ctx.params.query["after"]?
    limit = ctx.params.query["limit"]? || 50

    query = Crecto::Repo::Query.where(channel_id: id)
        .order_by("created DESC")
        .limit(limit)

    unless before.nil?
        b = before.as(String).to_i32
        query.where("id < ?", [b])
    end

    unless after.nil?
        a = after.as(String).to_i32
        query.where("id > ?", [a])
    end
end
