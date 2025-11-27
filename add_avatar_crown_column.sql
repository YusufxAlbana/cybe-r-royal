-- Tambahkan kolom avatar_crown ke tabel players jika belum ada
ALTER TABLE players ADD COLUMN IF NOT EXISTS avatar_crown TEXT;

-- Tambahkan kolom role jika belum ada (untuk admin)
ALTER TABLE players ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';

-- Update existing users to have default role
UPDATE players SET role = 'user' WHERE role IS NULL;
