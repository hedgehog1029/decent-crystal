get "/api" do |ctx|
    next {decentVersion: "0.1.0"}.to_json
end

get "/api/settings" do |ctx|
    {settings: settings}.to_json
end

post "/api/settings" do |ctx|
    session = sessions.ensure(ctx)
    results = {} of String => String

    unless session.is_admin?
        raise Decent::UnauthorizedException.new(ctx)
    end

    if ctx.params.json.has_key?("name")
        settings.name = ctx.params.json["name"].as(String)
        results["name"] = "updated"
    end

    if ctx.params.json.has_key?("authorizationMessage")
        settings.authorizationMessage = ctx.params.json["authorizationMessage"].as(String)
        results["authorizationMessage"] = "updated"
    end

    {results: results}.to_json
end

get "/api/properties" do |ctx|
    {properties: config}.to_json
end
