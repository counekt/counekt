-- User
CREATE TABLE "user" (
    id SERIAL PRIMARY KEY,
    creation_datetime TIMESTAMP,
    auth_token VARCHAR(32) UNIQUE,
    auth_token_expiration TIMESTAMP,
    username VARCHAR(120) UNIQUE,
    email VARCHAR(120) UNIQUE,
    is_activated BOOLEAN DEFAULT FALSE,
    phone_number VARCHAR(15),
    password_hash VARCHAR(128),
    name VARCHAR(120),
    bio VARCHAR(160),
    birthdate TIMESTAMP,
    gender VARCHAR DEFAULT 'Unspecified',
    photo_id INTEGER,
    main_wallet_id INTEGER,
    location_id INTEGER,
    CONSTRAINT fk_user_photo_id FOREIGN KEY (photo_id) REFERENCES file (id),
    CONSTRAINT fk_user_main_wallet_id FOREIGN KEY (main_wallet_id) REFERENCES wallet (id),
    CONSTRAINT fk_user_location_id FOREIGN KEY (location_id) REFERENCES location (id)
);

CREATE TABLE location (
    id SERIAL PRIMARY KEY,
    location_address VARCHAR,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    sin_rad_lat DOUBLE PRECISION,
    cos_rad_lat DOUBLE PRECISION,
    rad_lng DOUBLE PRECISION,
    show_location BOOLEAN DEFAULT FALSE,
    is_visible BOOLEAN DEFAULT FALSE
);

CREATE TABLE skill (
    id SERIAL PRIMARY KEY,
    title VARCHAR(20),
    owner_id INTEGER,
    CONSTRAINT fk_skill_owner_id FOREIGN KEY (owner_id) REFERENCES "user" (id) ON DELETE CASCADE
);

-- many to many
CREATE TABLE followers (
    follower_id INTEGER,
    followed_id INTEGER,
    CONSTRAINT fk_followers_follower_id FOREIGN KEY (follower_id) REFERENCES "user" (id),
    CONSTRAINT fk_followers_followed_id FOREIGN KEY (followed_id) REFERENCES "user" (id)
);

-- many to many
CREATE TABLE associates (
    left_id INTEGER,
    right_id INTEGER,
    CONSTRAINT fk_associates_left_id FOREIGN KEY (left_id) REFERENCES "user" (id),
    CONSTRAINT fk_associates_right_id FOREIGN KEY (right_id) REFERENCES "user" (id)
);

-- Wallet
CREATE TABLE wallet (
    id SERIAL PRIMARY KEY,
    address VARCHAR(42)
);

-- many to many
CREATE TABLE spenders (
    spender_id INTEGER,
    wallet_id INTEGER,
    CONSTRAINT fk_spenders_spender_id FOREIGN KEY (spender_id) REFERENCES "user" (id),
    CONSTRAINT fk_spenders_wallet_id FOREIGN KEY (wallet_id) REFERENCES wallet (id)
);

-- many to many
CREATE TABLE permits (
    permit_id INTEGER,
    wallet_id INTEGER,
    CONSTRAINT fk_permits_permit_id FOREIGN KEY (permit_id) REFERENCES permit (id),
    CONSTRAINT fk_permits_wallet_id FOREIGN KEY (wallet_id) REFERENCES wallet (id)
);


CREATE TABLE permit (
    id SERIAL PRIMARY KEY,
    erc360_id INTEGER,
    bytes BYTEA,
    parent_id INTEGER,
    CONSTRAINT fk_permit_erc360_id FOREIGN KEY (erc360_id) REFERENCES erc360 (id) ON DELETE CASCADE,
    CONSTRAINT fk_permit_parent_id FOREIGN KEY (parent_id) REFERENCES permit (id)
);


-- File
CREATE TABLE file (
    id SERIAL PRIMARY KEY,
    replacement VARCHAR,
    filename VARCHAR,
    path VARCHAR(2048),
    is_empty BOOLEAN DEFAULT TRUE,
);

-- Notification
CREATE TABLE notification (
    id SERIAL PRIMARY KEY,
    seen BOOLEAN DEFAULT FALSE,
    receiver_id INTEGER,
    timestamp TIMESTAMP DEFAULT EXTRACT(EPOCH FROM NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'UTC')),
    -- The first 'AT TIME ZONE' performs the conversion, the second one assigns new time zone to the result.
    payload_json TEXT,
    CONSTRAINT fk_notification_receiver_id FOREIGN KEY (receiver_id) REFERENCES "user" (id) ON DELETE CASCADE
);

-- ERC360

CREATE TABLE erc360 (
    id SERIAL PRIMARY KEY,
    active BOOLEAN DEFAULT TRUE,
    address VARCHAR(42),
    block INTEGER,
    current_clock INTEGER DEFAULT 0,
    total_supply INTEGER DEFAULT 0,
    timeline_last_updated_at INTEGER,
    shards_last_updated_at INTEGER,
    bank_exchanges_last_updated_at INTEGER,
    dividend_claims_last_updated_at INTEGER,
    referendum_votes_last_updated_at INTEGER,
    symbol VARCHAR,
    handle VARCHAR UNIQUE,
    name VARCHAR,
    description VARCHAR,
    public BOOLEAN DEFAULT FALSE,
    photo_id INTEGER,
    location_id INTEGER,
    CONSTRAINT fk_erc360_photo_id FOREIGN KEY (photo_id) REFERENCES file (id),
    CONSTRAINT fk_erc360_location_id FOREIGN KEY (location_id) REFERENCES location (id)
);

CREATE TABLE erc360_shard (
    id SERIAL PRIMARY KEY,
    amount INTEGER,
    creation_timestamp BIGINT, -- Big Integers for Unix Timestamps will likely run out year 2262, Fri on Apr 11
    expiration_timestamp BIGINT, -- MAX_INT = 9223372036854775807
    identifier BIGINT,
    expiration_clock BIGINT,
    erc360_id INTEGER,
    wallet_id INTEGER,
    CONSTRAINT fk_erc360_shard_erc360_id FOREIGN KEY (erc360_id) REFERENCES erc360 (id) ON DELETE CASCADE,
    CONSTRAINT fk_erc360_shard_wallet_id FOREIGN KEY (wallet_id) REFERENCES wallet (id)
);


CREATE TABLE referendum (
    id SERIAL PRIMARY KEY,
    identifier INTEGER,
    clock BIGINT,
    timestamp BIGINT,
    duration INTEGER,
    implemented BOOLEAN DEFAULT FALSE,
    viable_amount INTEGER, -- shard amount viable for voting at creation 
    cast_amount INTEGER DEFAULT 0, -- total shard amount that has voted
    in_favor_amount INTEGER DEFAULT 0,
    erc360_id INTEGER,
    CONSTRAINT fk_referendum_erc360_id FOREIGN KEY (erc360_id) REFERENCES erc360 (id) ON DELETE CASCADE
);

CREATE TABLE proposal (
    id SERIAL PRIMARY KEY,
    index INTEGER,
    sig BYTEA(4), -- 4 byte signifier of erc360 method
    args BYTEA -- method arguments
    referendum_id INTEGER,
    CONSTRAINT fk_proposal_referendum_id FOREIGN KEY (referendum_id) REFERENCES referendum (id) ON DELETE CASCADE
);

CREATE TABLE vote (
    id SERIAL PRIMARY KEY,
    in_favor BOOLEAN,
    referendum_id INTEGER,
    erc360_shard_id INTEGER,
    CONSTRAINT fk_vote_referendum_id FOREIGN KEY (referendum_id) REFERENCES referendum (id) ON DELETE CASCADE,
    CONSTRAINT fk_vote_erc360_shard_id FOREIGN KEY (erc360_shard_id) REFERENCES erc360_shard (id)
);

CREATE TABLE event ( -- as seen on the timeline
    id SERIAL PRIMARY KEY,
    timestamp INTEGER,
    payload_json TEXT,
    block_hash VARCHAR(66),
    transaction_hash VARCHAR(66),
    log_index INTEGER,
    erc360_id INTEGER,
    CONSTRAINT fk_event_erc360_id FOREIGN KEY (erc360_id) REFERENCES erc360 (id) ON DELETE CASCADE
);

-- Bank
CREATE TABLE bank (
    id SERIAL PRIMARY KEY,
    name VARCHAR,
    erc360_id INTEGER REFERENCES erc360 (id),
    permit_id INTEGER REFERENCES permit (id),
    CONSTRAINT fk_bank_erc360_id FOREIGN KEY (erc360_id) REFERENCES erc360 (id) ON DELETE CASCADE,
    CONSTRAINT fk_bank_permit_id FOREIGN KEY (permit_id) REFERENCES permit (id) ON DELETE CASCADE
);

CREATE TABLE token ( -- storing the basics of an ERC20
    id SERIAL PRIMARY KEY,
    name VARCHAR,
    symbol VARCHAR,
    address VARCHAR(42) UNIQUE,
    decimals INTEGER DEFAULT 18
);

CREATE TABLE token_amount ( -- an ERC20 amount
    id SERIAL PRIMARY KEY,
    amount NUMERIC(78) DEFAULT 0, -- precise numeric necessary
    token_id INTEGER,
    CONSTRAINT fk_token_amount_token_id FOREIGN KEY (token_id) REFERENCES token (id) ON DELETE CASCADE
);

-- many to many (only one to many is used)
CREATE TABLE bank_token_amounts ( -- ERC20 amount connected to bank
    bank_id INTEGER,
    token_amount_id INTEGER,
    CONSTRAINT fk_bank_token_amounts_bank_id FOREIGN KEY (bank_id) REFERENCES bank (id) ON DELETE CASCADE,
    CONSTRAINT fk_bank_token_amounts_token_amount_id FOREIGN KEY (token_amount_id) REFERENCES token_amount (id) ON DELETE CASCADE
);

CREATE TABLE Dividend (
    id SERIAL PRIMARY KEY,
    erc360_id INTEGER,
    clock BIGINT,
    identifier INTEGER,
    initial_token_amount_id INTEGER,
    residual_token_amount_id INTEGER,
    CONSTRAINT fk_dividend_erc360_id FOREIGN KEY (erc360_id) REFERENCES erc360 (id) ON DELETE CASCADE,
    CONSTRAINT fk_dividend_initial_token_amount_id FOREIGN KEY (initial_token_amount_id) REFERENCES token_amount (id),
    CONSTRAINT fk_dividend_residual_token_amount_id FOREIGN KEY (residual_token_amount_id) REFERENCES token_amount (id)
);


CREATE TABLE dividend_claim (
    id SERIAL PRIMARY KEY,
    dividend_id INTEGER,
    token_amount_id INTEGER,
    erc360_shard_id INTEGER,
    CONSTRAINT fk_dividend_claim_dividend_id FOREIGN KEY (dividend_id) REFERENCES dividend (id) ON DELETE CASCADE,
    CONSTRAINT fk_dividend_claim_token_amount_id FOREIGN KEY (token_amount_id) REFERENCES token_amount (id),
    CONSTRAINT fk_dividend_claim_erc360_shard_id FOREIGN KEY (erc360_shard_id) REFERENCES erc360_shard (id)
);

-- Requests

CREATE TABLE user_to_user_request (
    id SERIAL PRIMARY KEY,
    type VARCHAR,
    sender_id INTEGER,
    receiver_id INTEGER,
    notification_id INTEGER,
    CONSTRAINT fk_user_to_user_request_sender_id FOREIGN KEY (sender_id) REFERENCES "user" (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_to_user_request_receiver_id FOREIGN KEY (receiver_id) REFERENCES "user" (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_to_user_request_notification_id FOREIGN KEY (notification_id) REFERENCES notification (id)
);

CREATE TABLE user_to_erc360_request (
    id SERIAL PRIMARY KEY,
    type VARCHAR,
    user_is_sender BOOLEAN,
    user_id INTEGER,
    erc360_id INTEGER,
    notification_id INTEGER,
    CONSTRAINT fk_user_to_erc360_request_user_id FOREIGN KEY (user_id) REFERENCES "user" (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_to_erc360_request_erc360_id FOREIGN KEY (erc360_id) REFERENCES erc360 (id) ON DELETE CASCADE,
    CONSTRAINT fk_user_to_erc360_request_notification_id FOREIGN KEY (notification_id) REFERENCES notification (id)
);
