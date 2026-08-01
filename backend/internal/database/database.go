package database

import (
	"context"
	_ "embed"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/jmoiron/sqlx"
	"github.com/tareeqmajdapp/backend/internal/logger"
	_ "modernc.org/sqlite"
)

//go:embed schema.sql
var schemaSQL string

func Open(dbPath string) (*sqlx.DB, error) {
	if dir := filepath.Dir(dbPath); dir != "." && dir != "" {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return nil, fmt.Errorf("create database directory: %w", err)
		}
	}

	db, err := sqlx.Open("sqlite", dbPath)
	if err != nil {
		return nil, fmt.Errorf("open sqlite database: %w", err)
	}

	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)
	db.SetConnMaxLifetime(0)

	pragmas := []string{
		"PRAGMA journal_mode = WAL",
		"PRAGMA synchronous = NORMAL",
		"PRAGMA foreign_keys = ON",
		"PRAGMA busy_timeout = 5000",
	}
	for _, p := range pragmas {
		if _, err := db.Exec(p); err != nil {
			db.Close()
			return nil, fmt.Errorf("apply pragma %q: %w", p, err)
		}
	}

	for _, stmt := range splitStatements(schemaSQL) {
		if _, err := db.Exec(stmt); err != nil {
			db.Close()
			return nil, fmt.Errorf("apply schema statement %q: %w", stmt, err)
		}
	}

	if err := ensureColumns(db); err != nil {
		db.Close()
		return nil, err
	}

	if err := dropRemovedColumns(db); err != nil {
		db.Close()
		return nil, err
	}

	logger.Info("SQLite database ready at %s (WAL mode, foreign keys enforced)", dbPath)
	return db, nil
}

var removedColumns = []struct {
	table, column string
	dropIndexes   []string
}{
	{"users", "status", []string{"idx_users_gender_role_status"}},
}

func dropRemovedColumns(db *sqlx.DB) error {
	for _, c := range removedColumns {
		var names []string
		if err := db.Select(&names, fmt.Sprintf("SELECT name FROM pragma_table_info(%q)", c.table)); err != nil {
			return fmt.Errorf("inspect columns of %s: %w", c.table, err)
		}
		exists := false
		for _, n := range names {
			if n == c.column {
				exists = true
				break
			}
		}
		if !exists {
			continue
		}
		for _, idx := range c.dropIndexes {
			if _, err := db.Exec(fmt.Sprintf("DROP INDEX IF EXISTS %s", idx)); err != nil {
				return fmt.Errorf("drop index %s: %w", idx, err)
			}
		}
		stmt := fmt.Sprintf("ALTER TABLE %s DROP COLUMN %s", c.table, c.column)
		if _, err := db.Exec(stmt); err != nil {
			return fmt.Errorf("drop column %s.%s: %w", c.table, c.column, err)
		}
		logger.Info("Dropped removed column %s.%s", c.table, c.column)
	}
	return nil
}

var addedColumns = []struct {
	table, column, definition string
}{
	{"users", "bio", "TEXT"},
	{"comments", "updated_at", "TEXT"},
	{"comments", "is_edited", "INTEGER NOT NULL DEFAULT 0"},
}

func ensureColumns(db *sqlx.DB) error {
	for _, c := range addedColumns {
		var names []string
		if err := db.Select(&names, fmt.Sprintf("SELECT name FROM pragma_table_info(%q)", c.table)); err != nil {
			return fmt.Errorf("inspect columns of %s: %w", c.table, err)
		}
		exists := false
		for _, n := range names {
			if n == c.column {
				exists = true
				break
			}
		}
		if exists {
			continue
		}
		stmt := fmt.Sprintf("ALTER TABLE %s ADD COLUMN %s %s", c.table, c.column, c.definition)
		if _, err := db.Exec(stmt); err != nil {
			return fmt.Errorf("add column %s.%s: %w", c.table, c.column, err)
		}
	}
	return nil
}

func splitStatements(sql string) []string {
	var noComments strings.Builder
	for _, line := range strings.Split(sql, "\n") {
		if idx := strings.Index(line, "--"); idx >= 0 {
			line = line[:idx]
		}
		noComments.WriteString(line)
		noComments.WriteByte('\n')
	}

	parts := strings.Split(noComments.String(), ";")
	statements := make([]string, 0, len(parts))
	for _, p := range parts {
		trimmed := strings.TrimSpace(p)
		if trimmed != "" {
			statements = append(statements, trimmed)
		}
	}
	return statements
}

func HealthCheck(db *sqlx.DB) error {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	var one int
	return db.GetContext(ctx, &one, "SELECT 1")
}
