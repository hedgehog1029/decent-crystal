module Decent
    class ApiHandler < Kemal::Handler
        def call(ctx)
            if ctx.request.path.starts_with?("/api")
                ctx.response.content_type = "application/json"
                ctx.response.headers["Access-Control-Allow-Origin"] = "*"

                begin
                    return call_next(ctx)
                rescue ex : Decent::ApiException
                    res = {error: ex}.to_json
                rescue ex : Exception
                    error = {code: "FAILED", message: ex.message}
                    res = {error: error}.to_json
                end

                ctx.response.status_code = 500
                ctx.response.print res
                ctx.response.close
            end

            return call_next(ctx)
        end
    end

    class OptionsHandler < Kemal::Handler
        def call(ctx)
            if ctx.request.method == "OPTIONS"
                allowed_methods = ["GET", "POST"].join ", "

                ctx.response.headers["Allow"] = allowed_methods
                ctx.response.headers["Access-Control-Allow-Methods"] = allowed_methods
                ctx.response.headers["Access-Control-Allow-Headers"] = ctx.request.headers["Access-Control-Request-Headers"]

                ctx.response.status_code = 200
                ctx.response.print "Success"
                ctx.response.close
            else
                return call_next(ctx)
            end
        end
    end

    class SessionHandler < Kemal::Handler
        def call(ctx)
            session_id = ctx.params.json["sessionID"]? ||
                ctx.params.query["sessionID"]? ||
                ctx.request.headers["x-session-id"]?

            if session_id.nil?
                return call_next(ctx)
            end

            ctx.set("session_id", session_id.as(String))
            return call_next(ctx)
        end
    end
end
