CREATE TABLE android_metadata (locale TEXT);
CREATE TABLE applicants (

      id
        TEXT PRIMARY KEY,

      document_type
        TEXT NOT NULL,

      document_number
        TEXT NOT NULL,

      first_name
        TEXT NOT NULL,

      last_name
        TEXT NOT NULL,

      birth_date
        TEXT NOT NULL,

      gender
        TEXT NOT NULL,

      schooling
        TEXT,

      program
        TEXT NOT NULL,

      phone
        TEXT,

      email
        TEXT,

      address
        TEXT,

      department
        TEXT,

      municipality
        TEXT,

      corregimiento
        TEXT,

      village
        TEXT,

      responsible_name
  TEXT,

responsible_role
  TEXT,

responsible_cedula
  TEXT,

      observations
        TEXT,

      sync_status
        TEXT NOT NULL,

      created_at
        TEXT NOT NULL,

      updated_at
        TEXT NOT NULL,

      is_deleted
        INTEGER NOT NULL DEFAULT 0,

      deleted_at
        TEXT
    , sync_attempts
      INTEGER NOT NULL DEFAULT 0, last_sync_attempt
      TEXT, last_sync_error
      TEXT, synced_at
      TEXT, created_by_user_id
              INTEGER, site_id
              INTEGER);
CREATE TABLE user_profile (

      id INTEGER PRIMARY KEY AUTOINCREMENT,

      name TEXT NOT NULL,

      username TEXT NOT NULL UNIQUE,

      role TEXT NOT NULL,

      email TEXT,

      phone TEXT,

      cedula TEXT,
municipality_id INTEGER,

site_id INTEGER,

password_hash TEXT NOT NULL,

      is_active INTEGER NOT NULL DEFAULT 1,

      image_path TEXT,

      created_at TEXT NOT NULL,

      updated_at TEXT NOT NULL

    , created_by_user_id
              INTEGER, activation_code_hash TEXT, must_change_password
              INTEGER NOT NULL DEFAULT 0);
CREATE TABLE sqlite_sequence(name,seq);
CREATE TABLE catalog_items (

      id
        INTEGER PRIMARY KEY AUTOINCREMENT,

      catalog_type
        TEXT NOT NULL,

      name
        TEXT NOT NULL,

      parent_id
        INTEGER NOT NULL DEFAULT 0,

      active
        INTEGER NOT NULL DEFAULT 1,

      created_at
        TEXT NOT NULL,

      updated_at
        TEXT NOT NULL

    );
CREATE TABLE departments (

      id
        INTEGER PRIMARY KEY AUTOINCREMENT,

      code
        TEXT UNIQUE,

      name
        TEXT NOT NULL COLLATE NOCASE UNIQUE,

      created_at
        TEXT NOT NULL
    );
CREATE TABLE municipalities (

      id
        INTEGER PRIMARY KEY AUTOINCREMENT,

      department_id
        INTEGER NOT NULL,

      code
        TEXT,

      name
        TEXT NOT NULL COLLATE NOCASE,

      created_at
        TEXT NOT NULL,

      FOREIGN KEY (
        department_id
      )
      REFERENCES departments (
        id
      )
      ON DELETE CASCADE,

      UNIQUE (
        department_id,
        name
      )
    );
CREATE TABLE corregimientos (

      id
        INTEGER PRIMARY KEY AUTOINCREMENT,

      municipality_id
        INTEGER NOT NULL,

      code
        TEXT,

      name
        TEXT NOT NULL COLLATE NOCASE,

      created_at
        TEXT NOT NULL,

      FOREIGN KEY (
        municipality_id
      )
      REFERENCES municipalities (
        id
      )
      ON DELETE CASCADE,

      UNIQUE (
        municipality_id,
        name
      )
    );
CREATE TABLE villages (

      id
        INTEGER PRIMARY KEY AUTOINCREMENT,

      department_id
        INTEGER,

      municipality_id
        INTEGER,

      corregimiento_id
        INTEGER,

      code
        TEXT,

      name
        TEXT NOT NULL COLLATE NOCASE,

      created_at
        TEXT NOT NULL,

      FOREIGN KEY (
        department_id
      )
      REFERENCES departments (
        id
      )
      ON DELETE SET NULL,

      FOREIGN KEY (
        municipality_id
      )
      REFERENCES municipalities (
        id
      )
      ON DELETE SET NULL,

      FOREIGN KEY (
        corregimiento_id
      )
      REFERENCES corregimientos (
        id
      )
      ON DELETE SET NULL,

      UNIQUE (
        municipality_id,
        corregimiento_id,
        name
      )
    );
CREATE TABLE calendar_activities (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      date TEXT NOT NULL,
      time TEXT NOT NULL,
      description TEXT NOT NULL
    , user_id INTEGER);
CREATE TABLE location_selection_frequency (
            location_type TEXT NOT NULL,
            location_id INTEGER NOT NULL,
            frequency INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (location_type, location_id)
          );
CREATE TABLE sites (
              id
                INTEGER PRIMARY KEY AUTOINCREMENT,

              name
                TEXT NOT NULL,

              address
                TEXT,

              active
                INTEGER NOT NULL DEFAULT 1,

              created_at
                TEXT NOT NULL,

              updated_at
                TEXT NOT NULL
            );
CREATE TABLE site_municipalities (
              site_id
                INTEGER NOT NULL,

              municipality_id
                INTEGER NOT NULL,

              PRIMARY KEY (
                site_id,
                municipality_id
              )
            );
CREATE TABLE deleted_usernames (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL COLLATE NOCASE,
              deleted_at TEXT NOT NULL
            );
CREATE TABLE sync_history (
      id
        INTEGER PRIMARY KEY AUTOINCREMENT,

      applicant_id
        TEXT NOT NULL,

      status
        TEXT NOT NULL,

      synced_at
        TEXT NOT NULL,

      attempts
        INTEGER NOT NULL DEFAULT 0,

      message
        TEXT
    , created_by_user_id
              INTEGER, site_id
              INTEGER);
CREATE TABLE user_catalog_items (

       id
         INTEGER PRIMARY KEY AUTOINCREMENT,

       user_id
         INTEGER NOT NULL,

       source_catalog_id
         INTEGER,

       catalog_type
         TEXT NOT NULL,

       name
         TEXT NOT NULL,

       parent_id
         INTEGER NOT NULL DEFAULT 0,

       active
         INTEGER NOT NULL DEFAULT 1,

       created_at
         TEXT NOT NULL,

       updated_at
         TEXT NOT NULL
     );
CREATE INDEX idx_user_catalog_items_user_type
     ON user_catalog_items (
       user_id,
       catalog_type,
       active
     );
CREATE TABLE user_catalog_state (

       user_id
         INTEGER PRIMARY KEY,

       initialized_at
         TEXT NOT NULL
     );
