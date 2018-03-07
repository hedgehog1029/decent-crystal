require "crypto/bcrypt/password"

module Decent
    class Sessions
        def initialize(@db : DB::Database)
        end

        getter db

        def ensure(ctx : HTTP::Server::Context) : Session
            session_id = ctx.get("session_id").as(String)

            raise Decent::InvalidSessionException.new("No session ID provided!") if session_id.nil?

            session = Session.retrieve(@db, session_id)
            session
        rescue DB::Error
            raise Decent::InvalidSessionException.new("No session with that ID!")
        end

        # Retrieve all the active sessions for a user
        def get_all_user_sessions(user_id : String) : Array(Session)
            session_list = [] of Session

            @db.query "select * from sessions where user_id=?", user_id do |rs|
                rs.each do
                    session_id, created, uid = rs.read(String, Int64, String)
                    session = Session.new(db, session_id, created, uid)

                    session_list << session
                end
            end

            session_list
        end

        def login(username : String, password : String) : Session?
            uid, username, remote_pw = @db.query_one "select * from authorization where username=?", username, as: { String, String, String }

            hashed = Crypto::Bcrypt::Password.create(password)

            if hashed == remote_pw
                Session.create(@db, uid)
            else
                nil
            end
        end
    end

    # Represents an active session
    class Session
        def initialize(@db : DB::Database, @id : String, @created : Int64, @user_id : String)
        end

        getter id, created, user_id

        def self.retrieve(db : DB::Database, id : String)
            sid, created, user = db.query_one "select * from sessions where id=?", id, as: { String, Int64, String }

            new db, sid, created, user
        end

        def self.create(db : DB::Database, user_id : String)
            id = Random::Secure.hex(12)
            created = Time.utc_now.epoch_ms

            db.exec "insert into sessions values (?, ?, ?)", id, created, user_id
            new db, id, created, user_id
        end

        def delete
            @db.exec "delete from sessions where id=?", @id
        end

        # Get time that session was created
        def get_created : Time
            Time.epoch_ms(@created)
        end

        def user
            User.retrieve(@db, @user_id)
        end

        def is_admin?
            user.permissionLevel == "admin"
        end

        def ensure_admin
            unless is_admin?
                raise Decent::MustBeAdminException.new("You must be an admin to modify this resource.")
            end
        end

        def to_json(builder : JSON::PullParser)
            builder.object do
                builder.field "id", @id
                builder.field "dateCreated", @created
            end
        end
    end

    class User
        JSON.mapping(
            id: String,
            username: String,
            avatarURL: String,
            permissionLevel: String,
            flair: String,
            online: Bool
        )

        def initialize(@id, @username, @avatarURL, @permissionLevel, @flair, @online)
        end

        def self.retrieve(db : DB::Database, id : String)
            id, username, avatar, perm, flair = db.query_one "select * from users where id=?", id, as: { String, String, String, String, String }
            online = false

            new id, username, avatar, perm, flair, online
        end
    end
end
