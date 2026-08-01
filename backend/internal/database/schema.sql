PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
    id                   TEXT PRIMARY KEY,
    name                 TEXT NOT NULL,
    username             TEXT NOT NULL,
    password_hash        TEXT NOT NULL,
    token_version        INTEGER NOT NULL DEFAULT 1,
    email                TEXT,
    phone                TEXT,
    section              TEXT,
    guardian_name        TEXT,
    guardian_phone       TEXT,
    gender               TEXT NOT NULL DEFAULT 'ذكر',
    subjects             TEXT NOT NULL DEFAULT '[]',
    notes                TEXT,
    photo_path           TEXT,
    school_name          TEXT,
    last_name_change_at  TEXT,
    role                 TEXT NOT NULL CHECK (role IN ('student','teacher','admin')),
    can_upload_lectures  INTEGER NOT NULL DEFAULT 0,
    created_at           TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username_nocase
    ON users (username COLLATE NOCASE);
CREATE INDEX IF NOT EXISTS idx_users_role ON users (role);
CREATE INDEX IF NOT EXISTS idx_users_gender_role ON users (gender, role);

CREATE TABLE IF NOT EXISTS lectures (
    id                TEXT PRIMARY KEY,
    title             TEXT NOT NULL,
    description       TEXT NOT NULL DEFAULT '',
    subject           TEXT NOT NULL,
    section           TEXT NOT NULL DEFAULT 'شعبة أ',
    teacher_id        TEXT NOT NULL REFERENCES users(id),
    teacher_name      TEXT NOT NULL,
    video_path        TEXT NOT NULL,
    cover_image_path  TEXT,
    date              TEXT NOT NULL,
    published_at      TEXT,
    duration          TEXT,
    file_size_bytes   INTEGER NOT NULL DEFAULT 0,
    is_published      INTEGER NOT NULL DEFAULT 1,
    created_at        TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_lectures_subject_section ON lectures (subject, section);
CREATE INDEX IF NOT EXISTS idx_lectures_teacher ON lectures (teacher_id);

CREATE TABLE IF NOT EXISTS comments (
    id               TEXT PRIMARY KEY,
    lecture_id       TEXT NOT NULL REFERENCES lectures(id) ON DELETE CASCADE,
    user_id          TEXT NOT NULL REFERENCES users(id),
    user_name        TEXT NOT NULL,
    user_photo_path  TEXT,
    content          TEXT NOT NULL,
    created_at       TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_comments_lecture ON comments (lecture_id);

CREATE TABLE IF NOT EXISTS lecture_ratings (
    id          TEXT PRIMARY KEY,
    lecture_id  TEXT NOT NULL REFERENCES lectures(id) ON DELETE CASCADE,
    user_id     TEXT NOT NULL REFERENCES users(id),
    stars       INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
    created_at  TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ratings_lecture_user ON lecture_ratings (lecture_id, user_id);

CREATE TABLE IF NOT EXISTS attendance_records (
    id                 TEXT PRIMARY KEY,
    student_id         TEXT NOT NULL REFERENCES users(id),
    student_name       TEXT NOT NULL,
    section            TEXT NOT NULL,
    subject            TEXT,
    date               TEXT NOT NULL,
    status             TEXT NOT NULL CHECK (status IN ('present','absent','excused')),
    recorded_by        TEXT NOT NULL REFERENCES users(id),
    recorded_by_name   TEXT NOT NULL,
    recorded_at        TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_attendance_section_date ON attendance_records (section, date);
CREATE INDEX IF NOT EXISTS idx_attendance_student ON attendance_records (student_id);

CREATE TABLE IF NOT EXISTS community_posts (
    id               TEXT PRIMARY KEY,
    user_id          TEXT NOT NULL REFERENCES users(id),
    user_name        TEXT NOT NULL,
    user_photo_path  TEXT,
    title            TEXT,
    content          TEXT NOT NULL,
    image_path       TEXT,
    video_path       TEXT,
    is_pinned        INTEGER NOT NULL DEFAULT 0,
    created_at       TEXT NOT NULL,
    updated_at       TEXT
);

CREATE INDEX IF NOT EXISTS idx_community_posts_created ON community_posts (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_posts_pinned ON community_posts (is_pinned DESC, created_at DESC);

CREATE TABLE IF NOT EXISTS community_comments (
    id               TEXT PRIMARY KEY,
    post_id          TEXT NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id          TEXT NOT NULL REFERENCES users(id),
    user_name        TEXT NOT NULL,
    user_photo_path  TEXT,
    content          TEXT NOT NULL,
    created_at       TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_community_comments_post ON community_comments (post_id);

CREATE TABLE IF NOT EXISTS community_reports (
    id            TEXT PRIMARY KEY,
    post_id       TEXT NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    reported_by   TEXT NOT NULL REFERENCES users(id),
    reason        TEXT,
    status        TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','dismissed','resolved')),
    created_at    TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_community_reports_post ON community_reports (post_id);
CREATE INDEX IF NOT EXISTS idx_community_reports_status ON community_reports (status);

CREATE TABLE IF NOT EXISTS lecture_progress (
    user_id               TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lecture_id            TEXT NOT NULL REFERENCES lectures(id) ON DELETE CASCADE,
    started_at            TEXT NOT NULL,
    last_position_seconds REAL NOT NULL DEFAULT 0,
    watched_seconds       REAL NOT NULL DEFAULT 0,
    duration_seconds      REAL NOT NULL DEFAULT 0,
    percent               REAL NOT NULL DEFAULT 0,
    completed             INTEGER NOT NULL DEFAULT 0,
    completed_at          TEXT,
    updated_at            TEXT NOT NULL,
    PRIMARY KEY (user_id, lecture_id)
);

CREATE INDEX IF NOT EXISTS idx_lecture_progress_lecture ON lecture_progress (lecture_id);
CREATE INDEX IF NOT EXISTS idx_lecture_progress_updated ON lecture_progress (updated_at);
CREATE INDEX IF NOT EXISTS idx_lecture_progress_completed ON lecture_progress (completed);
