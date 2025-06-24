-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Profiles table (no partitioning)
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    bio TEXT,
    interests TEXT[],
    profile_photo_url TEXT,
    photo_urls TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_active TIMESTAMPTZ,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_profiles_created_at ON profiles(created_at);
CREATE INDEX idx_profiles_updated_at ON profiles(updated_at);
CREATE INDEX idx_profiles_last_active ON profiles(last_active);
CREATE INDEX idx_profiles_is_active ON profiles(is_active);

-- Venues table
CREATE TABLE venues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    location GEOGRAPHY(POINT) NOT NULL,
    venue_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

ALTER TABLE venues ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_venues_location ON venues USING GIST(location);
CREATE INDEX idx_venues_created_at ON venues(created_at);
CREATE INDEX idx_venues_is_active ON venues(is_active);

-- Check-ins table (no partitioning)
CREATE TABLE check_ins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    venue_id UUID NOT NULL,
    location GEOGRAPHY(POINT) NOT NULL,
    check_in_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expected_duration_minutes INTEGER NOT NULL,
    check_out_time TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (venue_id) REFERENCES venues(id)
);

ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_check_ins_user_id ON check_ins(user_id);
CREATE INDEX idx_check_ins_venue_id ON check_ins(venue_id);
CREATE INDEX idx_check_ins_location ON check_ins USING GIST(location);
CREATE INDEX idx_check_ins_check_in_time ON check_ins(check_in_time);
CREATE INDEX idx_check_ins_is_active ON check_ins(is_active);

-- Swipes table (no partitioning)
CREATE TABLE swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    swiper_id UUID NOT NULL,
    swiped_id UUID NOT NULL,
    direction VARCHAR(10) NOT NULL CHECK (direction IN ('left', 'right')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    check_in_id UUID,
    UNIQUE(swiper_id, swiped_id)
);

ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_swipes_swiper_id ON swipes(swiper_id);
CREATE INDEX idx_swipes_swiped_id ON swipes(swiped_id);
CREATE INDEX idx_swipes_direction ON swipes(direction);
CREATE INDEX idx_swipes_created_at ON swipes(created_at);

-- Matches table
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID NOT NULL,
    user2_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(user1_id, user2_id)
);

ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_matches_user1_id ON matches(user1_id);
CREATE INDEX idx_matches_user2_id ON matches(user2_id);
CREATE INDEX idx_matches_expires_at ON matches(expires_at);
CREATE INDEX idx_matches_is_active ON matches(is_active);

-- Messages table (no partitioning)
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL,
    sender_id UUID NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (match_id) REFERENCES matches(id)
);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_messages_match_id ON messages(match_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_messages_is_read ON messages(is_read);

-- Blocks table
CREATE TABLE blocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID NOT NULL,
    blocked_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id)
);

ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_blocks_blocker_id ON blocks(blocker_id);
CREATE INDEX idx_blocks_blocked_id ON blocks(blocked_id);
CREATE INDEX idx_blocks_created_at ON blocks(created_at);

-- Reports table
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL,
    reported_id UUID NOT NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'pending'
);

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_reports_reporter_id ON reports(reporter_id);
CREATE INDEX idx_reports_reported_id ON reports(reported_id);
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_created_at ON reports(created_at);

-- Notifications table (no partitioning)
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    related_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- User preferences table
CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY,
    preferred_gender VARCHAR(20)[],
    min_age INTEGER NOT NULL DEFAULT 18,
    max_age INTEGER NOT NULL DEFAULT 100,
    max_distance_km INTEGER NOT NULL DEFAULT 50,
    show_profile BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX idx_user_preferences_created_at ON user_preferences(created_at);

-- Function to automatically update updated_at columns
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at columns
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_venues_updated_at
    BEFORE UPDATE ON venues
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create matches when two users swipe right
CREATE OR REPLACE FUNCTION create_match_on_mutual_swipe()
RETURNS TRIGGER AS $$
DECLARE
    mutual_swipe_exists BOOLEAN;
    match_id UUID;
BEGIN
    IF NEW.direction = 'right' THEN
        SELECT EXISTS (
            SELECT 1 FROM swipes
            WHERE swiper_id = NEW.swiped_id
            AND swiped_id = NEW.swiper_id
            AND direction = 'right'
        ) INTO mutual_swipe_exists;

        IF mutual_swipe_exists THEN
            INSERT INTO matches (user1_id, user2_id, expires_at)
            VALUES (
                LEAST(NEW.swiper_id, NEW.swiped_id),
                GREATEST(NEW.swiper_id, NEW.swiped_id),
                NOW() + INTERVAL '3 days'
            ) RETURNING id INTO match_id;

            INSERT INTO notifications (user_id, type, content, related_id)
            VALUES (NEW.swiper_id, 'match', 'You have a new match!', match_id);

            INSERT INTO notifications (user_id, type, content, related_id)
            VALUES (NEW.swiped_id, 'match', 'You have a new match!', match_id);
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_match_trigger
    AFTER INSERT ON swipes
    FOR EACH ROW EXECUTE FUNCTION create_match_on_mutual_swipe();

-- Function to check if users are blocked
CREATE OR REPLACE FUNCTION check_if_blocked(user1 UUID, user2 UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM blocks
        WHERE (blocker_id = user1 AND blocked_id = user2)
        OR (blocker_id = user2 AND blocked_id = user1)
    );
END;
$$ LANGUAGE plpgsql;