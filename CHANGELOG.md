# Changelog

All notable changes to NDM File Timestamp are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.6.0] - 2026-10-28

### Added

- `--check-script` (and `SCRIPT_CHECK=on`) also says whether a newer version has been
  released, with its link and how to update. In a clone of the repository without local
  changes, `--check-script` offers to update it with `git pull` (it always asks first).
  The exit code is unchanged.
- README: how to update (section "Updating" under "Installation").

## [1.5.0] - 2026-10-26

### Added

- `--archive` also writes the report of the run, as shown on screen (without colors),
  next to each archive: `<file>_bundle_<YYYYMMDD>-<HHMMSS>.log`. It records which proofs
  and attachments were valid when the archive was made. No log is left when no archive is
  made.

## [1.4.0] - 2026-10-26

First public release. NDM File Timestamp was written in 2023 and has been used privately
since then; this release publishes it after a full review and a rewrite for public use
and for portability (Linux, Windows in WSL, macOS).

### Added

- RFC 3161 timestamps of a file from three independent Time Stamping Authorities
  (FreeTSA, DigiCert, Sectigo), with one request that contains only the SHA-256 hash: the
  content of the file never leaves the computer. Every download is limited to 30 seconds
  and 1 MB, so a misbehaving server cannot keep the script waiting or fill the disk.
- Each timestamp is checked right away against the TSA certificates, at the date signed
  by the TSA (a wrong clock on the computer does not matter). Only verified timestamps
  count as a success; one that could not be verified is still kept and reported as
  such.
- Every timestamp is checked only against the root certificate of its own TSA, never
  against one that comes with the proofs. The three roots are downloaded once into
  `ndm_file-timestamp-certs/` (after asking, on a terminal), showing for each one the
  expected and the obtained SHA-256, and kept only if it matches the value published
  by the TSA. They are required: if they are declined or cannot be downloaded, the
  script stops before contacting any TSA. They can also be downloaded and checked by
  hand: the script recognizes them by their content. A timestamp that leads to an
  unknown root is reported as such.
- `--get-certs`: shows the root certificates and downloads the missing ones.
- `--verify-certs`: checks, offline, that every root certificate is there and unaltered,
  and reports any other file in their folder.
- A root certificate file reformatted by its TSA is still accepted when it holds just
  the same certificate (same fingerprint).
- Stamping warns, from two years before, when the root certificate of a TSA in use is
  about to expire: new timestamps will then need a newer version of the script.
- One proof folder per run, `ndm_file-timestamp-proofs/<file>_<YYYYMMDD>-<HHMMSS>/` (UTC),
  next to the script (its real location, also through a symbolic link), so earlier proofs
  are never overwritten, not even for two runs in the same second; the folder is created
  again if it is missing. It holds the request, the responses, the certificates,
  a readable copy of each timestamp, the checksum, the file details and a `README.txt`
  with the manual verification steps; next to it, `<folder>.log` is the report of the run
  as shown on screen.
- Several files in one run (`FILE...`), each with its own proof folder, and a final
  summary of every file; all the files must exist before anything is sent. `--` ends the
  options, for file names that start with `-`. File names with spaces work everywhere.
- `-d`, `--output-dir DIR`: save the proofs in `DIR` (created if missing) instead of the
  folder next to the script; `--verify` searches `DIR` too.
- `-l`, `--list`: the proofs saved in the proof folder (or in `DIR`), with file, date of
  the run, number of timestamps and start of the hash.
- `--verify FILE...`: checks each file against all its proofs (next to the script, in
  `DIR`, and in a proof folder in the current directory or next to the file), and shows
  the earliest date proved. Proofs are recognized by the content of the file, so a
  renamed or moved copy is verified too. Certificates are checked at the date of each
  timestamp, so proofs stay verifiable after the TSA certificates expire. A modified file
  is reported as such.
- `-a`, `--archive FILE...`: verifies each file, then packs it with its valid proofs,
  the script, its license and the checked root certificates in one `.tar`, verifiable on its
  own anywhere, also offline. Archives
  go to `ndm_file-timestamp-archives/` next to the script (created again if missing).
- `--attach FILE|DIR` (with `--archive` and one file): packs the documents that go with
  the file, such as a signed declaration of authorship or PEC receipts, in
  `attachments/` of the same archive, with their valid proofs. An attachment without
  valid timestamps is packed anyway, with a warning, and the archive's `README.txt` says
  which attachments the timestamps confirm.
- `--requirements`: the needed tools and the install command for the common Linux
  distributions and macOS. The system CA certificates are found on Debian/Ubuntu, Arch,
  Alpine, Fedora/RHEL, openSUSE and macOS.
- Runs on Linux, on Windows in WSL and on macOS, where nothing needs to be installed;
  OpenSSL 3 is recommended. With LibreSSL (the `openssl` of macOS) or OpenSSL 1.1,
  Sectigo timestamps are kept but cannot be verified, and the script says why; with
  LibreSSL, `--verify` also warns that timestamps whose TSA certificate has expired
  cannot be verified.
- Optional configuration file `ndm_file-timestamp.conf` (template:
  `ndm_file-timestamp.conf.example`), only read, never executed: `OUTPUT_DIR`,
  `ARCHIVE_DIR`, `TSAS` (which TSAs to ask), `MIN_TIMESTAMPS` (how many different TSAs
  must confirm a file), `SCRIPT_CHECK` and `COLORS`. The environment wins over the file,
  the command line over both; an invalid value stops with exit code 2.
- `--check-script`: compares the script with the one published on GitHub for its
  version; with `SCRIPT_CHECK=on` this runs before every stamp, verification or archive.
  The README also describes an independent check that does not rely on the script.
- `file-info.txt` records the SHA-256 of the script that made the proofs.
- Colors only on a terminal, never with `COLORS=off` or `NO_COLOR` set: output saved to a file or sent
  through a pipe is plain text.
- `--version`, `--help`; exit codes 0 (success), 1 (error), 2 (invalid usage).
- `QUICKSTART.md` (English) and `QUICKSTART.it.md` (Italian): the whole procedure to
  protect a work, step by step, with a real example.
- `templates/`: a declaration of authorship of a work (English and Italian), with
  placeholders, date and signature, and the text of a PEC message (Italian), to use
  together with the proofs.
- `ndm_file-timestamp-files/` and `ndm_file-timestamp-attachments/`: suggested places,
  next to the script, for your files to stamp and for the documents that go with them
  (filled-in templates, receipts), kept apart from the program; Git ignores their
  contents.

[Unreleased]: https://github.com/nidamanx/NDM_File-Timestamp/compare/v1.6.0...HEAD
[1.6.0]: https://github.com/nidamanx/NDM_File-Timestamp/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/nidamanx/NDM_File-Timestamp/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/nidamanx/NDM_File-Timestamp/releases/tag/v1.4.0
