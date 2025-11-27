# Setup Database untuk Royal Cyber Casino

## ⚠️ PENTING - Jalankan Query Ini di Supabase!

### 1. Tambahkan Kolom ke Tabel Players

Buka **Supabase Dashboard → SQL Editor**, lalu jalankan:

```sql
-- Tambahkan kolom avatar_crown ke tabel players jika belum ada
ALTER TABLE players ADD COLUMN IF NOT EXISTS avatar_crown TEXT;

-- Tambahkan kolom role jika belum ada (untuk admin)
ALTER TABLE players ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user';

-- Update existing users to have default role
UPDATE players SET role = 'user' WHERE role IS NULL;
```

### 2. Buat Tabel Feedback

Jalankan query dari file `supabase_feedback_table.sql` atau copy-paste:

```sql
-- Drop table jika sudah ada (hati-hati, ini akan menghapus data!)
DROP TABLE IF EXISTS feedback CASCADE;

-- Tabel untuk menyimpan feedback dari user
CREATE TABLE feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    user_email TEXT NOT NULL,
    category TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT DEFAULT 'unread',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT feedback_category_check CHECK (category IN ('bug', 'feature', 'complaint', 'other')),
    CONSTRAINT feedback_status_check CHECK (status IN ('unread', 'read'))
);

-- Index untuk performa query
CREATE INDEX idx_feedback_user_id ON feedback(user_id);
CREATE INDEX idx_feedback_status ON feedback(status);
CREATE INDEX idx_feedback_created_at ON feedback(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Policy: User bisa insert feedback mereka sendiri
CREATE POLICY "Users can insert their own feedback"
ON feedback FOR INSERT
TO authenticated
WITH CHECK (auth.uid()::text = user_id);

-- Policy: User bisa melihat feedback mereka sendiri
CREATE POLICY "Users can view their own feedback"
ON feedback FOR SELECT
TO authenticated
USING (auth.uid()::text = user_id);

-- Policy: Admin bisa melihat semua feedback
CREATE POLICY "Admins can view all feedback"
ON feedback FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM players
        WHERE players.id = auth.uid()::text
        AND players.role = 'admin'
    )
);

-- Policy: Admin bisa update feedback (mark as read, dll)
CREATE POLICY "Admins can update feedback"
ON feedback FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM players
        WHERE players.id = auth.uid()::text
        AND players.role = 'admin'
    )
);

-- Policy: Admin bisa delete feedback
CREATE POLICY "Admins can delete feedback"
ON feedback FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM players
        WHERE players.id = auth.uid()::text
        AND players.role = 'admin'
    )
);
```

### 3. Set User Sebagai Admin

Untuk mengakses Inbox Admin, set user sebagai admin:

```sql
-- Ganti 'EMAIL_ANDA' dengan email user yang ingin dijadikan admin
UPDATE players 
SET role = 'admin' 
WHERE id = (
    SELECT id FROM auth.users WHERE email = 'EMAIL_ANDA@example.com'
);
```

## Troubleshooting

### Search User Tidak Menampilkan Data

1. **Buka Console Browser** (tekan F12)
2. **Lihat tab Console** untuk error message
3. **Cek apakah ada data di tabel players:**
   ```sql
   SELECT * FROM players LIMIT 10;
   ```
4. **Pastikan kolom `avatar_crown` dan `role` sudah ada:**
   ```sql
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'players';
   ```

### Inbox Admin Tidak Muncul

1. Pastikan user sudah di-set sebagai admin (lihat langkah 3)
2. Cek di database:
   ```sql
   SELECT id, full_name, role FROM players WHERE role = 'admin';
   ```

### Feedback Tidak Terkirim

1. Pastikan tabel `feedback` sudah dibuat (lihat langkah 2)
2. Cek RLS policies sudah aktif
3. Lihat error di Console Browser (F12)

## Testing

1. **Test Search User:**
   - Klik menu "Cari User"
   - Buka Console Browser (F12)
   - Lihat log "Fetching users..." dan "Fetch result:"
   - Jika ada error, screenshot dan laporkan

2. **Test Profile:**
   - Klik avatar/nama di sidebar
   - Coba edit nama
   - Coba upload foto

3. **Test Feedback:**
   - Klik menu "Feedback"
   - Isi form dan kirim
   - Cek di Supabase → Table Editor → feedback

4. **Test Inbox Admin:**
   - Set user sebagai admin (langkah 3)
   - Klik menu "Inbox"
   - Lihat semua feedback yang masuk

## Deploy

Setelah semua setup selesai:

```bash
vercel --prod
```

Selamat! Semua fitur sudah berfungsi! 🎉
