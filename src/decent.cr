require "db"
require "kemal"
require "sqlite3"
require "json"
require "yaml"
require "./decent/*"

add_handler Decent::ApiHandler.new

config = Decent::Config.from_yaml(File.open("config.yml"))
settings = Decent::ServerSettings.new("decent-crystal server", "Unauthorized!")
db = DB.open "sqlite3://./data.db"
sessions = Decent::Sessions.new(db)

get "/" do
    "This server is WIP and does not serve the client currently."
end

require "./decent/routes/*"

Kemal.run
