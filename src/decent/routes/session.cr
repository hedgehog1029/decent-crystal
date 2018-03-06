get "/api/sessions" do |ctx|
    session = sessions.ensure(ctx)

    list = sessions.get_all_user_sessions(session.user_id)
    {sessions: list}.to_json
end

post "/api/sessions" do |ctx|
    user = ctx.params.json["username"].as(String)
    pass = ctx.params.json["pass"].as(String)

    result = sessions.login(user, pass)

    if result.nil?
        
    else

    end
end
