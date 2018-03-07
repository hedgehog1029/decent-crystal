module Decent
    class Message
        JSON.mapping(
            id: String,
            channel_id: {type: String, key: "channelID"},
            text: String,
            author_id: {type: String, key: "authorID"},
            author_name: {type: String, key: "authorUsername"},
            author_avatar: {type: String, key: "authorAvatarURL"},
            created: {type: Int64, key: "dateCreated"},
            edited: {type: Int64?, key: "dateEdited"},
            reactions: Array(String)
        )

        def initialize(@id, @channel_id, @text, @author_id, @author_name, @author_avatar, @created, @edited, @reactions)
        end

        getter id, channel_id, text, author_id, created, edited, reactions

        def self.create(db : DB::Database, channel_id : String, text : String, user : Decent::User)
            id = Random::DEFAULT.hex(10)
            created = Time.utc_now.epoch_ms
            reactions = Array(String).new

            db.exec "insert into messages values (?, ?, ?, ?, ?, ?, ?)", id, channel_id, text, user.id, created, nil, reactions
            new id, channel_id, text, user.id, user.username, user.avatarURL, created, nil, reactions
        end

        def self.retrieve(db : DB::Database, message_id : String)
            r = db.query_one "select * from messages where id=?", message_id, as: {String, String, String, String, Int64, Int64?, String}
            id, channel_id, text, user_id, created, edited, reactions_txt = r
            reactions = Array(String).from_json(reactions_txt)

            user = Decent::User.retrieve(db, user_id)

            new id, channel_id, text, user_id, user.username, user.avatarURL, created, edited, reactions
        end

        def author(db : DB::Database)
            Decent::User.retrieve(db, @author_id)
        end

        def edit(db : DB::Database, text : String)
            db.exec "update messages set text=? where id=?", text, @id
            @text = text
        end

        def delete(db : DB::Database)
            db.exec "delete from messages where id=?", @id
        end
    end
end

post "/api/messages" do |ctx|
    session = ctx.ensure_session
    channel_id = ctx.params.json["channelID"].as(String)
    text = ctx.params.json["text"].as(String)
    user = session.user

    msg = Decent::Message.create(ctx.db, channel_id, text, user)
    {messageID: msg.id}.to_json
end

get "/api/messages/:id" do |ctx|
    message_id = ctx.params.url["id"].as(String)
    msg = Decent::Message.retrieve(ctx.db, message_id)

    {message: msg}.to_json
rescue DB::Error
    raise Decent::NotFoundException.new("That message wasn't found.")
end

patch "/api/messages/:id" do |ctx|
    session = ctx.ensure_session
    message_id = ctx.params.url["id"].as(String)
    new_text = ctx.params.json["text"].as(String)

    msg = Decent::Message.retrieve(ctx.db, message_id)
    session.ensure_owner(msg.author_id)
    msg.edit(ctx.db, new_text)

    Decent.empty_json
rescue DB::Error
    raise Decent::NotFoundException.new("That message wasn't found.")
end

delete "/api/messages/:id" do |ctx|
    session = ctx.ensure_session
    message_id = ctx.params.url["id"].as(String)
    msg = Decent::Message.retrieve(ctx.db, message_id)

    unless session.is_admin?
        session.ensure_owner(msg.author_id)
    end

    msg.delete(ctx.db)
    Decent.empty_json
end
