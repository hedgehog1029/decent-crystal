require "kemal"
require "sqlite3"
require "crecto"
require "json"
require "yaml"
require "./decent/*"

add_handler Decent::ApiHandler.new
add_handler Decent::OptionsHandler.new
add_handler Decent::SessionHandler.new

get "/" do |ctx|
    index = File.join(Kemal.config.public_folder, "index.html")
    send_file ctx, index
end

ws "/" do |socket, ctx|
    ctx.sockets.new_socket(socket)
end

require "./decent/routes/*"

# Kemal.config.logging = false
Kemal.config.port = 4040
Kemal.run
