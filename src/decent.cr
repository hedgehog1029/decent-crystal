require "db"
require "kemal"
require "sqlite3"
require "json"
require "yaml"
require "./decent/*"

add_handler Decent::ApiHandler.new

class HTTP::Server
    class Context
        macro finished
            @decent_config = Decent::Config.from_yaml(File.open("config.yml"))
            @settings = Decent::ServerSettings.new("decent-crystal server", "Unauthorized!")
            @db : DB::Database = DB.open "sqlite3://./data.db"
            @sessions = Decent::Sessions.new(db)
        end

        def ensure_session
            @sessions.ensure(self)
        end

        getter decent_config, settings, db, sessions
    end
end

get "/" do
    "This server is WIP and does not serve the client currently."
end

require "./decent/routes/*"

# Kemal.config.logging = false
Kemal.run
