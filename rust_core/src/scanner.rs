use std::borrow::Cow;
use std::path::Path;

use lofty::file::{AudioFile, TaggedFileExt};
use lofty::tag::Accessor;
use uuid::Uuid;
use walkdir::WalkDir;

use crate::error::{CoreError, CoreResult};
use crate::models::{Song, SongSource};

const SUPPORTED_EXTENSIONS: &[&str] = &[
    "aac", "aiff", "ape", "flac", "m4a", "mp3", "mp4", "mpc", "oga", "ogg", "opus",
    "spx", "wav", "wv",
];

pub(crate) fn scan_directory(root: &Path) -> CoreResult<Vec<Song>> {
    if !root.is_dir() {
        return Err(CoreError::InvalidInput(format!(
            "music directory does not exist or is not a directory: {}",
            root.display()
        )));
    }

    let mut songs = WalkDir::new(root)
        .follow_links(false)
        .into_iter()
        // Unreadable entries should not make the whole library disappear. A later
        // diagnostics API can expose skipped paths to the UI.
        .filter_map(Result::ok)
        .filter(|entry| entry.file_type().is_file())
        .map(|entry| entry.into_path())
        .filter(|path| is_supported_audio_file(path))
        .filter_map(|path| song_from_path(&path).ok())
        .collect::<Vec<_>>();

    songs.sort_unstable_by(|left, right| {
        left.artist
            .cmp(&right.artist)
            .then_with(|| left.album.cmp(&right.album))
            .then_with(|| left.title.cmp(&right.title))
    });

    Ok(songs)
}

fn song_from_path(path: &Path) -> CoreResult<Song> {
    let canonical_path = std::fs::canonicalize(path)?;
    let fallback_title = file_stem(&canonical_path);

    // A corrupt or unsupported tag must not prevent a playable file from appearing
    // in the catalog, hence all metadata fields have safe fallbacks.
    let tagged_file = lofty::read_from_path(&canonical_path).ok();
    let tag = tagged_file
        .as_ref()
        .and_then(|file| file.primary_tag().or_else(|| file.first_tag()));

    let title = tag
        .and_then(|value| normalized(value.title()))
        .unwrap_or(fallback_title);
    let artist = tag.and_then(|value| normalized(value.artist()));
    let album = tag.and_then(|value| normalized(value.album()));
    let duration_seconds = tagged_file.as_ref().and_then(|file| {
        let seconds = file.properties().duration().as_secs();
        u32::try_from(seconds).ok().filter(|value| *value > 0)
    });

    let path_string = canonical_path.to_string_lossy().into_owned();
    let stable_id = Uuid::new_v5(&Uuid::NAMESPACE_URL, path_string.as_bytes());

    Ok(Song {
        id: format!("local:{stable_id}"),
        title,
        artist,
        album,
        // Embedded artwork extraction belongs in the cache layer. Keeping this
        // nullable prevents large image blobs from crossing FFI during a scan.
        cover_art_url_or_path: None,
        stream_url_or_file_path: path_string,
        duration_seconds,
        source: SongSource::Local,
    })
}

fn is_supported_audio_file(path: &Path) -> bool {
    path.extension()
        .and_then(|extension| extension.to_str())
        .is_some_and(|extension| {
            SUPPORTED_EXTENSIONS
                .iter()
                .any(|supported| extension.eq_ignore_ascii_case(supported))
        })
}

fn file_stem(path: &Path) -> String {
    path.file_stem()
        .and_then(|value| value.to_str())
        .filter(|value| !value.trim().is_empty())
        .unwrap_or("Unknown title")
        .to_owned()
}

fn normalized(value: Option<Cow<'_, str>>) -> Option<String> {
    value
        .map(|value| value.trim().to_owned())
        .filter(|value| !value.is_empty())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn recognizes_extensions_case_insensitively() {
        assert!(is_supported_audio_file(Path::new("track.FLAC")));
        assert!(is_supported_audio_file(Path::new("track.mp3")));
        assert!(!is_supported_audio_file(Path::new("cover.jpg")));
    }
}
