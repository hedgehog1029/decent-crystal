class DChannel < Crecto::Model
    include Crecto::Schema

    schema "channels" do
        field :name, String
        has_many :pins, Message, foreign_key: "channel_id"
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
        field :channel_id, PkeyValue
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

    ctx.sockets.broadcast "channel/new", channel: r.instance
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

    ctx.sockets.broadcast "channel/update", channel: channel
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

    ctx.sockets.broadcast "channel/delete", channelID: channel.id
    Decent.empty_json
end

post "/api/channels/:id/mark-read" do |ctx|
    session = ctx.ensure_session

    id = ctx.params.url["id"]?.assert_string.to_i32
    last_msg = Repo.get_by(Message, channel_id: id).as(Message?)
    next Decent.empty_json if last_msg.nil?

    user_id = Repo.get_association(session, :user).as(Decent::User).id
    ack = Repo.get_by(Ack, user_id: user_id, channel_id: id) || Ack.new
    ack.user_id = user_id
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
        .order_by("created_at DESC")
        .limit(limit.to_i32)

    unless before.nil?
        b = before.as(String).to_i32
        query.where("id < ?", [b])
    end

    unless after.nil?
        a = after.as(String).to_i32
        query.where("id > ?", [a])
    end

    messages = Repo.all(Message, query)
    {messages: messages}.to_json
end

get "/api/channels/:id/pins" do |ctx|
    id = ctx.params.url["id"]?.assert_string.to_i32
    channel = Repo.get(DChannel, id)
    assert_found channel, "That channel wasn't found!"

    pins = Repo.get_association(channel, :pins).as(Array(Message))

    {pins: pins}.to_json
end

post "/api/channels/:id/pins" do |ctx|
    session = ctx.ensure_session
    session.ensure_admin

    id = ctx.params.url["id"]?.assert_string.to_i32
    msg_id = ctx.params.json["messageID"]?.assert_string.to_i32
    channel = Repo.get(DChannel, id)
    message = Repo.get(Message, msg_id)
    assert_found channel, message, "Channel or message not found."

    pins = Repo.get_association(channel, :pins).as(Array(Message))
    assert_found pins, "Pins do not exist?"

    pins << message
    Repo.update(channel)

    ctx.sockets.broadcast "channel/pins/add", message: message
    Decent.empty_json
end

delete "/api/channels/:id/pins/:pin_id" do |ctx|
    session = ctx.ensure_session
    session.ensure_admin

    ch_id = ctx.params.url["id"]?.assert_string.to_i32
    msg_id = ctx.params.url["pin_id"]?.assert_string.to_i32

    channel = Repo.get(DChannel, ch_id)
    message = Repo.get(Message, msg_id)
    assert_found channel, message, "Channel or message not found."

    pins = Repo.get_association(channel, :pins).as(Array(Message))
    assert_found pins, "Pins do not exist?"

    pins.delete(message)
    Repo.update(channel)

    ctx.sockets.broadcast "channel/pins/remove", messageID: msg_id
    Decent.empty_json
end
