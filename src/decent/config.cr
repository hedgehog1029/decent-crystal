module Decent
    class Config
        include YAML::Serializable

        property useSecure : Bool
        property useAuthorization : Bool

        def to_json(builder : JSON::Builder)
            builder.object do
                builder.field "useSecure", @useSecure
                builder.field "useAuthorization", @useAuthorization
            end
        end
    end
end
