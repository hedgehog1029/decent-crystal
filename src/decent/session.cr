module Decent
    class UnauthorizedException < Kemal::Exceptions::CustomException
        def initialize(context : HTTP::Server::Context)
            context.response.status_code = 401
            super context
        end
    end

    class Sessions
        def initialize(@db : DB::Database)
        end

        getter db

        def ensure(ctx : HTTP::Server::Context) : Session
            session_id = ctx.get("session_id").as(String)

            raise UnauthorizedException.new(ctx) if session_id.nil?

            session = Session.retrieve(@db, session_id)
            session
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

        def login(username : String, password : String) : String?
            
        end
    end

    # Represents an active session
    class Session
        def initialize(@db : DB::Database, @id : String, @created : Int64, @user_id : String)
        end

        getter id, created, user_id

        # Get time that session was created
        def get_created : Time
            Time.epoch_ms(@created)
        end

        def self.retrieve(db : DB::Database, id : String)
            sid, created, user = db.query_one "select * from sessions where id=?", id, as: { String, Int64, String }

            new db, sid, created, user
        end

        def user
            User.retrieve(@db, @user_id)
        end

        def is_admin?
            user.permissionLevel == "admin"
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
