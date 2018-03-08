get "/api/users" do |ctx|
    users = Repo.all(Decent::User)

    {users: users}.to_json
end

post "/api/users" do |ctx|
    username = ctx.params.json["username"]?.assert_string
    password = ctx.params.json["password"]?.assert_string

    assert_valid_name username
    raise Decent::ShortPasswordException.new("Password is too short.") if password.size < 6

    pw_hash = Crypto::Bcrypt::Password.create(password)
    user = Decent::User.new

    user.username = username
    user.avatar = ""
    user.permissionLevel = "user"
    user.password = pw_hash.to_s

    rs = Repo.insert(user)
    raise Decent::NameAlreadyTakenException.new("An error occured") unless rs.valid?

    ctx.sockets.broadcast "user/new", user: rs.instance
    {user: rs.instance}.to_json
end

get "/api/users/:id" do |ctx|
    id = ctx.params.url["id"]?.assert_string.to_i32
    user = Repo.get(Decent::User, id)
    assert_found user, "That user wasn't found."

    {user: user}.to_json
end

patch "/api/users/:id" do |ctx|
    session = ctx.ensure_session

    id = ctx.params.url["id"]?.assert_string.to_i32
    user = Repo.get(Decent::User, id)
    assert_found user, "That user wasn't found."

    unless session.is_admin?
        session.ensure_owner(id)
    end

    flair = ctx.params.json["flair"]?
    unless flair.nil?
        user.flair = flair.assert_string
    end

    pw_obj = ctx.params.json["password"]?
    unless pw_obj.nil?
        pw = pw_obj.as(Hash(String, JSON::Type))
        # pw["old"]
    end

    # TODO: implement all of this endpoint
    rs = Repo.update(user)
    ctx.sockets.broadcast "user/update", user: rs.instance
    Decent.empty_json
end

get "/api/username-available/:username" do |ctx|
    username = ctx.params.url["username"]?.assert_string

    u = Repo.get_by(Decent::User, username: username)
    available = u.nil?

    {available: available}.to_json
end
