CREATE TABLE emotes (shortcode text primary key on conflict rollback, created_at bigint, updated_at bigint, url text);
CREATE TABLE sessions (sid text primary key asc on conflict rollback, created_at bigint, updated_at bigint, user_id int not null);
CREATE TABLE users (id integer primary key asc on conflict rollback autoincrement, created_at bigint, updated_at bigint, username text unique on conflict rollback, avatar text, permissionLevel varchar(16), flair text, password text);
CREATE TABLE messages (id integer primary key asc on conflict rollback autoincrement, created_at bigint, updated_at bigint, channel_id integer, text text, user_id integer, edited bigint);
CREATE TABLE channels (id integer primary key asc on conflict rollback autoincrement, created_at bigint, updated_at bigint, name text);
