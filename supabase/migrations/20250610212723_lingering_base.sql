CREATE TABLE IF NOT EXISTS `mwr_songs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) NOT NULL,
  `name` varchar(500) DEFAULT 'Unknown',
  `author` varchar(255) DEFAULT 'Unknown',
  `maxDuration` int(11) DEFAULT 300,
  PRIMARY KEY (`id`),
  UNIQUE KEY `url` (`url`),
  KEY `idx_url` (`url`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mwr_playlists` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT 'New Playlist',
  `owner` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mwr_playlist_songs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `playlist` int(11) NOT NULL,
  `song` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_playlist` (`playlist`),
  KEY `idx_song` (`song`),
  KEY `idx_playlist_song` (`playlist`, `song`),
  CONSTRAINT `fk_playlist_songs_playlist` FOREIGN KEY (`playlist`) REFERENCES `mwr_playlists` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_playlist_songs_song` FOREIGN KEY (`song`) REFERENCES `mwr_songs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mwr_playlists_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `playlist` int(11) NOT NULL,
  `license` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),d
  KEY `idx_playlist` (`playlist`),
  KEY `idx_license` (`license`),
  KEY `idx_playlist_license` (`playlist`, `license`),
  CONSTRAINT `fk_playlists_users_playlist` FOREIGN KEY (`playlist`) REFERENCES `mwr_playlists` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;