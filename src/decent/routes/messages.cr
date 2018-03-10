class Message < Crecto::Model
    include Crecto::Schema

    schema "messages" do
        field :channel_id, PkeyValue
        field :text, String
        belongs_to :user, Decent::User
        field :edited, Int64
    end

    validate_required [:channel_id, :text]

    def to_json(builder : JSON::Builder)
        builder.object do
            user = Repo.get_association(self, :user).as(Decent::User)
            raise "Invalid user" if user.nil?

            builder.field "id", @id
            builder.field "channelID", @channel_id
            builder.field "text", @text
            builder.field "authorID", user.id
            builder.field "authorUsername", user.username
            builder.field "authorAvatarURL", user.avatar
            builder.field "dateCreated", @created_at
            builder.field "dateEdited", @edited
        end
    end
end

post "/api/messages" do |ctx|
    session = ctx.ensure_session
    channel_id = ctx.params.json["channelID"]?.assert_string.to_i32
    text = ctx.params.json["text"]?.assert_string
    user = session.user

    msg = Message.new
    msg.channel_id = channel_id
    msg.text = text
    msg.user = user
    ch = Repo.insert(msg)

    raise Decent::InvalidParameterException.new("Error committing data.") unless ch.valid?
    ctx.sockets.broadcast "message/new", message: msg

    {messageID: ch.instance.id}.to_json
end

get "/api/messages/:id" do |ctx|
    message_id = ctx.params.url["id"].assert_string.to_i32
    msg = Repo.get(Message, message_id)
    raise Decent::NotFoundException.new("That message wasn't found.") if msg.nil?

    {message: msg}.to_json
end

patch "/api/messages/:id" do |ctx|
    session = ctx.ensure_session
    message_id = ctx.params.url["id"].assert_string.to_i32
    new_text = ctx.params.json["text"].assert_string

    msg = Repo.get(Message, message_id)
    raise Decent::NotFoundException.new("That message wasn't found.") if msg.nil?

    session.ensure_owner(msg.user_id)
    msg.text = new_text
    Repo.update(msg)

    ctx.sockets.broadcast "message/edit", message: msg
    Decent.empty_json
end

delete "/api/messages/:id" do |ctx|
    session = ctx.ensure_session
    message_id = ctx.params.url["id"].assert_string.to_i32
    msg = Repo.get(Message, message_id)
    raise Decent::NotFoundException.new("That message wasn't found.") if msg.nil?

    unless session.is_admin?
        session.ensure_owner(msg.user_id)
    end

    Repo.delete(msg)
    Decent.empty_json
end
