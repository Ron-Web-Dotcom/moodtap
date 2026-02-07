-- Moods Tracking Module Migration
-- Purpose: Store user mood history with date tracking

-- Create moods table (idempotent)
CREATE TABLE IF NOT EXISTS public.moods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    mood_date DATE NOT NULL,
    mood_value INTEGER NOT NULL CHECK (mood_value >= 1 AND mood_value <= 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, mood_date)
);

-- Create indexes for performance (idempotent)
CREATE INDEX IF NOT EXISTS idx_moods_user_id ON public.moods(user_id);
CREATE INDEX IF NOT EXISTS idx_moods_mood_date ON public.moods(mood_date);
CREATE INDEX IF NOT EXISTS idx_moods_user_date ON public.moods(user_id, mood_date);

-- Enable RLS
ALTER TABLE public.moods ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists to avoid conflicts
DROP POLICY IF EXISTS "public_moods_access" ON public.moods;

-- RLS Policy: Allow all operations with anon key (device-based auth)
-- This allows the app to work without requiring anonymous auth provider in dashboard
CREATE POLICY "public_moods_access"
ON public.moods
FOR ALL
TO anon
USING (true)
WITH CHECK (true);

-- Function to update updated_at timestamp (idempotent)
CREATE OR REPLACE FUNCTION public.update_moods_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS moods_updated_at_trigger ON public.moods;

-- Trigger to automatically update updated_at
CREATE TRIGGER moods_updated_at_trigger
    BEFORE UPDATE ON public.moods
    FOR EACH ROW
    EXECUTE FUNCTION public.update_moods_updated_at();