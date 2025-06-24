-- Additional SQL functions for Skip The Chase app

-- Function to get nearby venues
CREATE OR REPLACE FUNCTION get_nearby_venues(lat FLOAT, lng FLOAT, radius_km FLOAT)
RETURNS TABLE (
    id UUID,
    name VARCHAR(100),
    address TEXT,
    latitude FLOAT,
    longitude FLOAT,
    venue_type VARCHAR(50),
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.id,
        v.name,
        v.address,
        ST_Y(v.location::geometry) as latitude,
        ST_X(v.location::geometry) as longitude,
        v.venue_type,
        v.created_at,
        v.updated_at,
        v.is_active
    FROM venues v
    WHERE v.is_active = true
    AND ST_DWithin(
        v.location,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
        radius_km * 1000
    )
    ORDER BY ST_Distance(
        v.location,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get nearby checked-in users
CREATE OR REPLACE FUNCTION get_nearby_checked_in_users(lat FLOAT, lng FLOAT, radius_meters FLOAT)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    birth_date DATE,
    gender VARCHAR(20),
    bio TEXT,
    interests TEXT[],
    profile_photo_url TEXT,
    photo_urls TEXT[],
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_active TIMESTAMPTZ,
    is_verified BOOLEAN,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        p.first_name,
        p.last_name,
        p.birth_date,
        p.gender,
        p.bio,
        p.interests,
        p.profile_photo_url,
        p.photo_urls,
        p.created_at,
        p.updated_at,
        p.last_active,
        p.is_verified,
        p.is_active
    FROM profiles p
    INNER JOIN check_ins c ON p.user_id = c.user_id
    WHERE c.is_active = true
    AND c.check_out_time IS NULL
    AND NOW() < (c.check_in_time + INTERVAL '1 minute' * c.expected_duration_minutes)
    AND ST_DWithin(
        c.location,
        ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
        radius_meters
    )
    AND p.is_active = true;
END;
$$ LANGUAGE plpgsql;

-- Function to get swipeable users (excluding already swiped and blocked users)
CREATE OR REPLACE FUNCTION get_swipeable_users(current_user_id UUID, limit_count INTEGER)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    birth_date DATE,
    gender VARCHAR(20),
    bio TEXT,
    interests TEXT[],
    profile_photo_url TEXT,
    photo_urls TEXT[],
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_active TIMESTAMPTZ,
    is_verified BOOLEAN,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.user_id,
        p.first_name,
        p.last_name,
        p.birth_date,
        p.gender,
        p.bio,
        p.interests,
        p.profile_photo_url,
        p.photo_urls,
        p.created_at,
        p.updated_at,
        p.last_active,
        p.is_verified,
        p.is_active
    FROM profiles p
    WHERE p.user_id != current_user_id
    AND p.is_active = true
    AND p.user_id NOT IN (
        -- Exclude already swiped users
        SELECT s.swiped_id 
        FROM swipes s 
        WHERE s.swiper_id = current_user_id
    )
    AND NOT check_if_blocked(current_user_id, p.user_id)
    ORDER BY RANDOM()
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up expired matches
CREATE OR REPLACE FUNCTION cleanup_expired_matches()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE matches 
    SET is_active = false 
    WHERE expires_at < NOW() 
    AND is_active = true;
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- Function to clean up expired check-ins
CREATE OR REPLACE FUNCTION cleanup_expired_checkins()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE check_ins 
    SET is_active = false, check_out_time = NOW()
    WHERE (check_in_time + INTERVAL '1 minute' * expected_duration_minutes) < NOW()
    AND is_active = true
    AND check_out_time IS NULL;
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- Row Level Security Policies

-- Profiles policies
CREATE POLICY "Users can view active profiles" ON profiles
    FOR SELECT USING (is_active = true);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Check-ins policies
CREATE POLICY "Users can view active check-ins" ON check_ins
    FOR SELECT USING (is_active = true);

CREATE POLICY "Users can insert their own check-ins" ON check_ins
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own check-ins" ON check_ins
    FOR UPDATE USING (auth.uid() = user_id);

-- Swipes policies
CREATE POLICY "Users can insert their own swipes" ON swipes
    FOR INSERT WITH CHECK (auth.uid() = swiper_id);

CREATE POLICY "Users can view swipes involving them" ON swipes
    FOR SELECT USING (auth.uid() = swiper_id OR auth.uid() = swiped_id);

-- Matches policies
CREATE POLICY "Users can view their own matches" ON matches
    FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Messages policies
CREATE POLICY "Users can view messages in their matches" ON messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM matches m 
            WHERE m.id = match_id 
            AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
        )
    );

CREATE POLICY "Users can insert messages in their matches" ON messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM matches m 
            WHERE m.id = match_id 
            AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
            AND m.is_active = true
        )
    );

-- Blocks policies
CREATE POLICY "Users can insert their own blocks" ON blocks
    FOR INSERT WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can view their own blocks" ON blocks
    FOR SELECT USING (auth.uid() = blocker_id);

-- Reports policies
CREATE POLICY "Users can insert their own reports" ON reports
    FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON notifications
    FOR INSERT WITH CHECK (true);

-- User preferences policies
CREATE POLICY "Users can manage their own preferences" ON user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Venues policies
CREATE POLICY "Anyone can view active venues" ON venues
    FOR SELECT USING (is_active = true);