use std::path::PathBuf;

use tokio::task;

use crate::database;
use crate::models::{Song, SongSource};
use crate::{scanner, subsonic};

/// Creates (or migrates) the catalog database and makes it active for later calls.
///
/// Flutter supplies the path because it owns the platform-aware application data
/// directory on both Android and Linux.
pub async fn init_db(database_path: String) -> Result<(), String> {
    let database_path = require_non_empty(database_path, "database_path")?;
    database::init(PathBuf::from(database_path))
        .await
        .map_err(|error| error.to_string())
}

/// Recursively scans a directory, reads audio tags with `lofty`, and replaces the
/// local portion of the catalog in one SQLite transaction.
pub async fn scan_local_music(path: String) -> Result<Vec<Song>, String> {
    let path = require_non_empty(path, "path")?;
    let root = PathBuf::from(path);

    // Filesystem traversal and metadata decoding are blocking operations. Moving
    // them to Tokio's blocking pool keeps the FRB async executor responsive.
    let songs = task::spawn_blocking(move || scanner::scan_directory(&root))
        .await
        .map_err(|error| format!("local music scan task failed: {error}"))?
        .map_err(|error| error.to_string())?;

    database::replace_source(SongSource::Local, songs.clone())
        .await
        .map_err(|error| error.to_string())?;

    Ok(songs)
}

/// Downloads the Subsonic catalog and atomically refreshes its SQLite cache.
///
/// The plaintext password is used only to create Subsonic token-authenticated
/// requests and is never written to the catalog database.
pub async fn fetch_subsonic_songs(
    server_url: String,
    username: String,
    password: String,
) -> Result<Vec<Song>, String> {
    let server_url = require_non_empty(server_url, "server_url")?;
    let username = require_non_empty(username, "username")?;
    let password = require_non_empty(password, "password")?;

    let songs = subsonic::fetch_songs(&server_url, &username, &password)
        .await
        .map_err(|error| error.to_string())?;

    database::replace_source(SongSource::Subsonic, songs.clone())
        .await
        .map_err(|error| error.to_string())?;

    Ok(songs)
}

/// Returns the unified local + Subsonic catalog.
pub async fn get_all_songs() -> Result<Vec<Song>, String> {
    database::get_all_songs()
        .await
        .map_err(|error| error.to_string())
}

fn require_non_empty(value: String, field: &str) -> Result<String, String> {
    let value = value.trim().to_owned();
    if value.is_empty() {
        Err(format!("{field} must not be empty"))
    } else {
        Ok(value)
    }
}
