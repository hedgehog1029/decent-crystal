module Decent
    class ServerSettings
        include JSON::Serializable

        property name : String
        property authorizationMessage : String

        def initialize(@name : String, @authorizationMessage : String)
        end
    end
end
