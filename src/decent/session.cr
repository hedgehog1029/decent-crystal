require "crypto/bcrypt/password"

module Decent
    class Sessions
        def ensure(ctx : HTTP::Server::Context) : Session
            session_id = ctx.get("session_id").as(String)

            session = Repo.get(Session, session_id)
            raise Decent::InvalidSessionException.new("No session with that ID!") if session.nil?
            session
        rescue KeyError
            raise Decent::InvalidSessionException.new("No session ID provided!")
        end

        def session?(ctx : HTTP::Server::Context) : Session?
            session_id = ctx.get("session_id").as(String)
            Repo.get(Session, session_id)
        rescue KeyError
            nil
        end

        # Retrieve all the active sessions for a user
        def get_all_user_sessions(user_id : PkeyValue) : Array(Session)
            query = Crecto::Repo::Query.where(user_id: user_id)
            sessions = Repo.all(Session, query)

            sessions.as(Array(Session))
        end

        def login(username : String, password : String) : Session?
            user = Repo.get_by(User, username: username)
            raise Decent::NotFoundException.new("User not found.") if user.nil?
            remote_pw = user.password.as(String)
            hashed = Crypto::Bcrypt::Password.new(remote_pw)

            if hashed.verify(password)
                session = Session.new
                session.sid = Random::Secure.hex(12)
                session.created_at = Time.utc
                session.user_id = user.id

                Repo.insert(session).instance
            else
                nil
            end
        end
    end

    # Represents an active session
    class Session < Crecto::Model
        include Crecto::Schema

        @user : User?

        schema "sessions" do
            field :sid, String, primary_key: true
            field :user_id, PkeyValue
        end

        def user
            if @user.nil?
                @user = Repo.get(User, @user_id)
            end

            @user.as(User)
        end

        def is_admin?
            user.permissionLevel == "admin"
        end

        def ensure_admin
            unless is_admin?
                raise Decent::MustBeAdminException.new("You must be an admin to modify this resource.")
            end
        end

        def ensure_owner(owner_id : PkeyValue)
            unless user.id == owner_id
                raise Decent::NotYoursException.new("You do not own this resource.")
            end
        end

        def to_json(builder : JSON::Builder)
            builder.object do
                builder.field "id", @sid
                builder.field "dateCreated", @created_at.try &.to_unix_ms
            end
        end
    end

    class User < Crecto::Model
        include Crecto::Schema

        schema "users" do
            field :username, String
            field :avatar, String
            field :permissionLevel, String
            field :flair, String
            field :password, String
        end

        unique_constraint :username
        validate_required [:username, :password, :permissionLevel]

        def to_json(builder : JSON::Builder)
            builder.object do
                builder.field "id", @id
                builder.field "username", @username
                builder.field "avatarURL", @avatar
                builder.field "permissionLevel", @permissionLevel
                builder.field "flair", @flair
            end
        end
    end
end
