module Decent
    class ApiException < Kemal::Exceptions::CustomException
        def initialize(@code : String, @message : String)
        end

        def to_json(builder : JSON::Builder)
            builder.object do
                builder.field "code", @code
                builder.field "message", @message

                unless extra_param.nil?
                    name, val = extra_param.not_nil!
                    builder.field name, val
                end
            end
        end

        def extra_param
            nil
        end

        getter code
    end

    class NotFoundException < ApiException
        def initialize(message : String)
            super "NOT_FOUND", message
        end
    end

    class NotYoursException < ApiException
        def initialize(message : String)
            super "NOT_YOURS", message
        end
    end

    class MustBeAdminException < ApiException
        def initialize(message : String)
            super "MUST_BE_ADMIN", message
        end
    end

    class AlreadyPerformedException < ApiException
        def initialize(message : String)
            super "ALREADY_PERFORMED", message
        end
    end

    class IncompleteParametersException < ApiException
        def initialize(message : String, missing : NamedTuple)
            super "INCOMPLETE_PARAMETERS", message

            @missing = [] of String
            missing.each { |k, v|
                (@missing << k.to_s) if v
            }
        end

        def extra_param
            {"missing", @missing}
        end
    end

    class InvalidParameterException < ApiException
        def initialize(message : String)
            super "INVALID_PARAMETER_TYPE", message
        end
    end

    class InvalidSessionException < ApiException
        def initialize(message : String)
            super "INVALID_SESSION_ID", message
        end
    end

    class UploadFailedException < ApiException
        def initialize(message : String)
            super "UPLOAD_FAILED", message
        end
    end

    class NameAlreadyTakenException < ApiException
        def initialize(message : String)
            super "NAME_ALREADY_TAKEN", message
        end
    end

    class ShortPasswordException < ApiException
        def initialize(message : String)
            super "SHORT_PASSWORD", message
        end
    end

    class IncorrectPasswordException < ApiException
        def initialize(message : String)
            super "INCORRECT_PASSWORD", message
        end
    end

    class InvalidNameException < ApiException
        def initialize(message : String)
            super "INVALID_NAME", message
        end
    end
end

# Helper macros + functions

macro assert_found(*vars)
    {% for name, i in vars %}
        {% if name != vars.last %}
            raise Decent::NotFoundException.new({{vars.last}}) if {{name.id}}.nil?
        {% end %}
    {% end %}
end

macro assert_exists(*vars)
    {% for name, i in vars %}
        {% if name != vars.last %}
            raise Decent::IncompleteParametersException.new({{vars.last}}, { {{name.id}}: true }) if {{name.id}}.nil?
        {% end %}
    {% end %}
end

def assert_valid_name(name : String)
    t = name =~ /^[a-zA-Z-_]+$/
    raise Decent::InvalidNameException.new("Name must contain only alphanumeric characters, with dashes and/or underscores") if t.nil?
end

class Object
    def assert_string
        raise Decent::IncompleteParametersException.new("Missing required parameter.", {string: true}) if self.nil?
        raise Decent::InvalidParameterException.new("Parameter was not a string.") unless self.is_a?(String)
        return self.as(String)
    end
end
