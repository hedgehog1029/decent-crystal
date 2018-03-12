get "/api/sessions" do |ctx|
    session = ctx.ensure_session

    list = ctx.sessions.get_all_user_sessions(session.user_id)
    {sessions: list}.to_json
end

post "/api/sessions" do |ctx|
    user = ctx.params.json["username"]?.assert_string
    pass = ctx.params.json["password"]?.assert_string

    result = ctx.sessions.login(user, pass)

    if result.nil?
        raise Decent::NotFoundException.new("The username or password is incorrect.")
    else
        {sessionID: result.sid}.to_json
    end
end

get "/api/sessions/:id" do |ctx|
    session_id = ctx.params.url["id"]?.assert_string

    session = Repo.get(Decent::Session, session_id)
    raise Decent::InvalidSessionException.new("Invalid session ID!") if session.nil?

    {session: session, user: session.user}.to_json
end

delete "/api/sessions/:id" do |ctx|
    session_id = ctx.params.url["id"]?.assert_string

    session = Repo.get(Decent::Session, session_id)
    Repo.delete(session) unless session.nil?

    Decent.empty_json
end
