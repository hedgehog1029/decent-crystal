require "kemal"
require "sqlite3"
require "crecto"
require "json"
require "yaml"
require "./decent/*"

add_handler Decent::ApiHandler.new

module Decent
    class Instances
        def initialize
            @config = Decent::Config.from_yaml(File.open("config.yml"))
            @settings = Decent::ServerSettings.new("decent-crystal server", "Unauthorized!")
            @sessions = Decent::Sessions.new
            @sockets = Decent::SocketHolder.new
        end

        getter config, settings, sessions, sockets
    end

    INSTANCES = Instances.new
end

class HTTP::Server
    class Context
        macro finished
            @decent_config : Decent::Config = Decent::INSTANCES.config
            @settings : Decent::ServerSettings = Decent::INSTANCES.settings
            @sessions : Decent::Sessions = Decent::INSTANCES.sessions
            @sockets : Decent::SocketHolder = Decent::INSTANCES.sockets
        end

        def ensure_session
            @sessions.ensure(self)
        end

        getter decent_config, settings, sessions, sockets
    end
end

get "/" do
    "This server is WIP and does not serve the client currently."
end

ws "/" do |socket, ctx|
    ctx.sockets.new_socket(socket)
end

require "./decent/routes/*"

# Kemal.config.logging = false
Kemal.run
