# NDM File Timestamp

**English** · [Italiano](README.it.md)

[![License: AGPL v3+](https://img.shields.io/badge/License-AGPL_v3%2B-blue.svg)](LICENSE)
![Version](https://img.shields.io/badge/version-1.6.0-informational)
![Shell](https://img.shields.io/badge/shell-bash-4EAA25)

**NDM File Timestamp** proves that a file existed, exactly as it is now, at a given time:
a proof of existence and integrity based on trusted timestamping. Three independent Time
Stamping Authorities (TSA) sign the file's SHA-256 hash together with their own date and
time (RFC 3161 timestamps), and the proofs can be verified at any time, by this script or
by hand with `openssl`.

It is one Bash script with no extra libraries: it relies on `openssl`, `curl` and the
standard system tools, and runs on Linux, on Windows in WSL and on macOS. Only the hash of
the file is sent over the network, never its content.

New here? **[QUICKSTART.md](QUICKSTART.md)** shows every step with a real example.

## Why

A file's own dates (creation, last modified) can be changed by anyone and prove
nothing. A timestamp signed by an independent authority can: it binds the file's hash
to a date that the owner of the file cannot alter. It works with any digital file:
source code or a release archive of a program, a binary, a dataset, images, video,
music, a manuscript, a design, a set of documents: anything you may later need to show
existed, in that exact form, at a certain date. It can help, for example, to defend
the copyright on a work: see [Legal value](#legal-value).

The script asks three authorities at once, keeps every response with the certificates
needed to check it, and stores everything in a folder that explains itself, so the
proof can be verified years later by anyone, with standard tools.

---

## Contents

- [How it works](#how-it-works)
  - [Root certificates](#root-certificates)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Windows (WSL)](#windows-wsl)
- [Usage](#usage)
- [Protecting a work, step by step](#protecting-a-work-step-by-step)
- [Configuration](#configuration)
- [The proof folder](#the-proof-folder)
- [Copies, moves and archives](#copies-moves-and-archives)
- [Verifying](#verifying)
  - [With the script](#with-the-script)
  - [By hand](#by-hand)
  - [In the long run](#in-the-long-run)
- [Checking the script](#checking-the-script)
- [Sample output](#sample-output)
- [Legal value](#legal-value)
- [External services contacted](#external-services-contacted)
- [Exit codes](#exit-codes)
- [Project layout](#project-layout)
- [Versioning](#versioning)
- [License and disclaimer](#license-and-disclaimer)

---

## How it works

1. The script computes the SHA-256 hash of the file and builds one RFC 3161 request
   that contains only that hash.
2. It sends the request to three independent Time Stamping Authorities:

   | TSA | Address | Notes |
   |-----|---------|-------|
   | FreeTSA | `https://freetsa.org/tsr` | free public TSA |
   | DigiCert | `http://timestamp.digicert.com` | used worldwide for code signing |
   | Sectigo | `http://timestamp.sectigo.com` | used worldwide for code signing |

3. Each TSA returns a signed timestamp: the hash, the TSA's date and time, and its
   signature. A response is kept only if the TSA **granted** the request.
4. Each timestamp is checked right away against the TSA certificates. The report keeps
   two things apart: **obtained** (the TSA answered and the response was saved) and
   **verified** (its signature was also checked here, at the date signed by the TSA, so a
   wrong clock on your computer does not matter). Only verified timestamps count as a
   success; one that could not be verified is still kept, and can be checked later.

Each timestamp is valid on its own; several independent authorities confirming the
same hash make the proof stronger, and the proof survives if one authority disappears.
No key, account, signature or password is needed.

DigiCert and Sectigo are contacted over plain HTTP. This is normal for RFC 3161: the
response is digitally signed and checked, so it cannot be altered without detection.

### Root certificates

A signature is only as trustworthy as the root certificate it is checked against. So
the script checks every timestamp only against the root certificate of **its** TSA, and
never uses one that comes with the proofs: whoever made fake proofs could have made that
certificate too. The three roots are kept in `ndm_file-timestamp-certs/` next to the
script. The repository does not contain them: each user downloads and checks their own.

| TSA | Root certificate | Download from | SHA-256 of the file |
|-----|------------------|---------------|---------------------|
| FreeTSA | FreeTSA Root CA (valid until 2041) | `https://freetsa.org/files/cacert.pem` | `2151b61137ffa86bf664691ba67e7da0b19f98c758e3d228d5d8ebf27e044438` |
| DigiCert | DigiCert Trusted Root G4 (2038) | `http://cacerts.digicert.com/DigiCertTrustedRootG4.crt` | `552f7bdcf1a7af9e6ce672017f4f12abf77240c78e761ac203d1d9d20ac89988` |
| Sectigo | USERTrust RSA Certification Authority (2038) | `http://crt.usertrust.com/USERTrustRSACertificationAuthority.crt` | `e793c9b02fd8aa13e21c31228accb08119643b749c898964b1746d46c3d4cbd2` |

These values are also written in the script, and you can compare them with independent
sources: FreeTSA publishes the SHA-256 of its file on [freetsa.org](https://freetsa.org).
The DigiCert and Sectigo `.crt` files are the bare certificates, so their SHA-256 is the
certificate fingerprint, the same as in the Mozilla CA list (the `ca-certificates`
package of your system) and on [crt.sh](https://crt.sh/). A download over plain HTTP is
fine: a file with another SHA-256 is never kept. Sectigo timestamps lead to the USERTrust
root (also run by Sectigo) because their certificate chain goes through it. The
expiry of a root does not matter for older timestamps: they are checked at their own date.

**They are required.** Without them no timestamp can be checked, and nothing would show
that a date really comes from a TSA. So, when one is missing, the script deals with it
before anything else (before contacting a TSA or creating a folder): it explains why,
lists the missing ones and, on a terminal, asks before downloading them. For each one it
shows the expected and the obtained SHA-256, and keeps only the files that match. If you
answer no, or a download fails, the script stops and reminds you how to get them.
`--get-certs` does the same at any time and shows which roots are present.

**By hand.** Download the three files into `ndm_file-timestamp-certs/` and check them:

```bash
cd ndm_file-timestamp-certs
curl -O https://freetsa.org/files/cacert.pem
curl -O http://cacerts.digicert.com/DigiCertTrustedRootG4.crt
curl -O http://crt.usertrust.com/USERTrustRSACertificationAuthority.crt
sha256sum *        # macOS: shasum -a 256 *
```

Each SHA-256 must be the one in the table and the one published by the TSA: delete any
file that does not match. If a TSA has reformatted its file, with the same certificate
inside, the script accepts it anyway when it holds just that certificate: compare then
the certificate fingerprint (`openssl x509 -in FILE -noout -fingerprint -sha256`;
FreeTSA: `a6379e7cecc05faa3cbf076013d745e327bbbaa38c0b9af22469d4701d18aabc`, for the
other two it is the value in the table). The script recognizes the roots by their content, whatever
the file names; `./ndm_file-timestamp.sh --get-certs` then shows them as `OK`.

**Checking them later.** `./ndm_file-timestamp.sh --verify-certs` checks, offline and
without changing anything, that every trusted root is there byte for byte (its SHA-256),
and reports any other file in the folder: `ALTERED` when it has the name of a root but
not its content. It ends with exit code 0 only when everything is in order. In an
extracted archive it checks the roots of the archive.

**New roots.** One day a TSA will start using a new root: see
[In the long run](#in-the-long-run).

## Requirements

| Tool | Needed for |
|------|------------|
| `openssl` | RFC 3161 requests, signature checks |
| `curl` | Sending the requests to the TSAs (not needed by `--verify`) |
| `sha256sum` (coreutils; on macOS `shasum`) | The file's hash |
| System CA certificates (`ca-certificates`) | The HTTPS downloads made by `curl` |

All of them are required. On Linux the script uses the GNU coreutils; on macOS it uses
the system's own tools (Bash 3.2, BSD `date` and `stat`, `shasum`), so nothing needs to
be installed there (OpenSSL 3 is recommended: see below). Run `./ndm_file-timestamp.sh --requirements` to see what is missing and the exact
install command for your system:

| System | Command |
|--------|---------|
| Debian / Ubuntu | `sudo apt install openssl curl coreutils ca-certificates` |
| Fedora / RHEL 8+ | `sudo dnf install openssl curl coreutils ca-certificates` |
| CentOS / RHEL 7 | `sudo yum install openssl curl coreutils ca-certificates` |
| openSUSE | `sudo zypper install openssl curl coreutils ca-certificates` |
| Arch / Manjaro | `sudo pacman -S openssl curl coreutils ca-certificates` |
| Alpine | `sudo apk add bash openssl curl coreutils ca-certificates` (bash first: Alpine does not include it) |
| macOS | Nothing: `openssl` (LibreSSL), `curl`, `shasum` and the certificates come with the system |
| Windows | Run it in WSL: see [Windows (WSL)](#windows-wsl) |

**OpenSSL 3 is recommended.** With LibreSSL (the `openssl` of macOS) or OpenSSL 1.1
(older Linux distributions) there are limits:

- **Sectigo timestamps do not verify.** These versions check the list of certificates
  in the timestamp more strictly than OpenSSL 3, and Sectigo's list does not include its
  root. The timestamps are still obtained and kept, the script says why they are not
  verified, and they verify with OpenSSL 3. FreeTSA and DigiCert verify as usual, so a
  file is still confirmed (unless `MIN_TIMESTAMPS` asks for all three TSAs).
- **Expired certificates (LibreSSL only).** LibreSSL may not support `-attime` in
  `openssl ts -verify`. Then `--verify` says so and checks the certificates at the
  current date: everything works until a TSA certificate expires (today's ones expire
  between 2037 and 2040), after which those timestamps no longer verify.

On macOS, install OpenSSL 3 with Homebrew and put it first in your `PATH` (add the
`export` line to `~/.zprofile` to keep it):

```bash
brew install openssl@3
export PATH="$(brew --prefix openssl@3)/bin:$PATH"
openssl version          # OpenSSL 3.x
```

## Installation

```bash
git clone https://github.com/nidamanx/NDM_File-Timestamp.git
cd NDM_File-Timestamp
chmod +x ndm_file-timestamp.sh
./ndm_file-timestamp.sh --requirements      # check the needed tools
```

Optional: make it available everywhere through a symbolic link. The script still saves
the proofs next to its real location.

```bash
ln -s "$PWD/ndm_file-timestamp.sh" ~/.local/bin/ndm_file-timestamp
```

### Windows (WSL)

The script needs a Linux shell. On Windows 10 and 11 run it inside **WSL** (Windows
Subsystem for Linux), which provides a real Ubuntu environment. Git Bash, MSYS2 and
Cygwin are not supported.

1. Open **PowerShell as administrator**, install WSL (Ubuntu by default) and restart
   Windows when asked:

   ```powershell
   wsl --install
   ```

2. Open **Ubuntu** from the Start menu, create your Linux user when asked, then install
   the tools and the script inside your Linux home directory:

   ```bash
   sudo apt update
   sudo apt install git openssl curl coreutils ca-certificates
   cd ~
   git clone https://github.com/nidamanx/NDM_File-Timestamp.git
   cd NDM_File-Timestamp
   ./ndm_file-timestamp.sh --requirements
   ```

Notes for Windows:

- Keep the script in the Linux home (`~`), not under `/mnt/c/...`: on Windows drives the
  executable permission may be lost.
- Your files on Windows are reachable from WSL under `/mnt/c/...`: give the script their
  path, for example `/mnt/c/Users/<you>/Documents/project.zip`. The proofs are saved next
  to the script, in the Linux home.
- Clone from inside WSL. The repository's `.gitattributes` keeps Linux line endings even
  if you clone with Git for Windows: Windows line endings (CRLF) would break the script
  with errors like `/usr/bin/env: 'bash\r': No such file or directory`.

### Updating

`--check-script` says when a newer version has been released. In a clone of the
repository, on branch `main` and without local changes, it also offers to update it on
the spot (the same can be done by hand):

```bash
cd NDM_File-Timestamp
git pull --ff-only
```

If you downloaded only the script, download the new one from the
[latest release](https://github.com/nidamanx/NDM_File-Timestamp/releases/latest),
replace the old file, run `chmod +x ndm_file-timestamp.sh` and check it as in
[Checking the script](#checking-the-script). If `git status` shows local changes, keep a
copy of them and discard them (`git checkout -- ndm_file-timestamp.sh`) before pulling.

Updating never touches your proofs, archives, root certificates or settings: they are
not part of the repository. Newer versions keep verifying the proofs made by older ones.

## Usage

```
./ndm_file-timestamp.sh [-d DIR] FILE...            create the timestamps
./ndm_file-timestamp.sh --verify [-d DIR] FILE...   check the files against their timestamps
./ndm_file-timestamp.sh --list [-d DIR]             list the saved proofs
./ndm_file-timestamp.sh --archive [-d DIR] FILE...  pack each file with its proofs and the script
./ndm_file-timestamp.sh --archive [-d DIR] FILE --attach FILE|DIR...
                                                    the same, with attachments
```

| Option | Description |
|--------|-------------|
| `--verify FILE...` | Check each `FILE` against **all** its proofs and show the dates they certify (UTC and local time), plus the earliest date proved. Contacts no TSA |
| `-l`, `--list` | List the proofs in the proof folder (or in `DIR` with `-d`, or `OUTPUT_DIR`): file, date of the run, number of timestamps and start of the hash. The run dates come from your computer's clock; the certified dates are shown by `--verify` |
| `-a`, `--archive FILE...` | Verify each `FILE`, then pack it with its valid proofs, the root certificates, this script and its license in one `.tar` in the archive folder next to the script (see [Copies, moves and archives](#copies-moves-and-archives)) |
| `--attach FILE\|DIR` | With `--archive` and one `FILE` only: also pack this file, or every file directly inside `DIR`, in `attachments/` of the archive, with their valid proofs (for example a signed declaration of authorship, PEC receipts). Repeatable. An attachment without valid timestamps is packed anyway, with a warning |
| `-d`, `--output-dir DIR` | Save the proofs in `DIR` instead of the folder next to the script, for example on a backup disk. `DIR` is created if missing; a relative `DIR` starts from the current directory. With `--verify`, `DIR` is searched too |
| `--` | End of the options: what follows are files, even when their name starts with `-` |
| `--check-script` | Compare this script with the one published on GitHub for its version (see [Checking the script](#checking-the-script)) |
| `--get-certs` | Show the root certificates of the TSAs and download the missing ones, showing every check (see [Root certificates](#root-certificates)) |
| `--verify-certs` | Check, offline, that every root certificate is there and unaltered, and that nothing else is in their folder |
| `--requirements` | Show the needed tools and how to install them |
| `-v`, `--version` | Show name, version, author, license and disclaimer |
| `-h`, `--help` | Show the help |

Examples:

```bash
# Create the proofs for a file
~/NDM_File-Timestamp/ndm_file-timestamp.sh ~/Documents/project.zip

# Several files at once
~/NDM_File-Timestamp/ndm_file-timestamp.sh contract.pdf drawings.zip notes.odt

# Proofs saved on a backup disk instead of next to the script
~/NDM_File-Timestamp/ndm_file-timestamp.sh -d /media/backup/proofs project.zip

# Later: check the file against its proofs
~/NDM_File-Timestamp/ndm_file-timestamp.sh --verify ~/Documents/project.zip

# Which proofs are there?
~/NDM_File-Timestamp/ndm_file-timestamp.sh --list

# The file, its proofs and the script in one archive, to keep or move
~/NDM_File-Timestamp/ndm_file-timestamp.sh --archive ~/Documents/project.zip

# The same, with the signed declaration and the receipts that go with the file
~/NDM_File-Timestamp/ndm_file-timestamp.sh --archive ~/Documents/project.zip \
    --attach ~/Documents/declaration.pdf --attach ~/Documents/receipts/
```

With several files, each one gets its own proof folder and its own report, and a final
summary shows the result of every file. All the files must exist before anything is sent.
Every run creates new proof folders, so you can stamp the same file again later:
`--verify` then lists every set of proofs and the earliest date.
A file whose name starts with `-` is given after `--`, or with a path such as
`./-notes.txt`.

The files to stamp can be anywhere. If you like, keep them in `ndm_file-timestamp-files/`
next to the script, and the documents that go with them (filled-in
[templates](templates/), receipts) in `ndm_file-timestamp-attachments/`: like the proof
folder, both are part of the repository, empty except for a `.gitkeep` file, and Git
ignores their contents, so your files stay apart from the program and are never
committed by mistake. The script does not look there by itself: give the path, for
example `./ndm_file-timestamp.sh ndm_file-timestamp-files/project.zip`.

Colors are used only when the output goes to a terminal; set `COLORS=off` in the
configuration file, or `NO_COLOR=1`, to turn them off there too. Output saved to a file or
sent through a pipe is plain text.

## Protecting a work, step by step

**[QUICKSTART.md](QUICKSTART.md)** walks through the whole procedure with a real example,
from installation to the archive kept in two places. In short:

1. Stamp the work (and every important version, drafts too).
2. Verify it and note the SHA-256 and the "at least since" date.
3. Fill in the [declaration of authorship](templates/) and sign it.
4. Stamp the signed declaration.
5. Optional: PEC, qualified timestamp or registration with the body of your country.
6. Pack everything with `--archive FILE --attach FOLDER`.
7. Keep the archive in two places and check every copy with `--verify`.

See [Legal value](#legal-value) for what these proofs are worth.

## Configuration

The defaults work without any configuration. To change them without typing options at
every run, create a configuration file next to the script, starting from the template:

```bash
cp ndm_file-timestamp.conf.example ndm_file-timestamp.conf
```

| Setting | Default | Meaning |
|---------|---------|---------|
| `OUTPUT_DIR` | the proof folder next to the script | Folder of the proofs: relative to the script folder, or absolute. `-d` wins over it. Proofs already saved next to the script are still found by `--verify` |
| `ARCHIVE_DIR` | the archive folder next to the script | Folder where `--archive` creates the archives: relative to the script folder, or absolute |
| `TSAS` | `freetsa digicert sectigo` | The TSAs to ask, space or comma separated |
| `MIN_TIMESTAMPS` | `1` | How many different TSAs must confirm a file, when stamping and when verifying. A higher value gives a stronger proof, but one TSA out of service is then enough to fail |
| `SCRIPT_CHECK` | `off` | `on`: compare the script with the published one before each run (see [Checking the script](#checking-the-script)) |
| `COLORS` | `on` | `off`: no colors |

- One `KEY=value` per line; lines starting with `#` are ignored; quotes are optional.
- The file is only read, never executed: commands written in it are not run.
- It is personal and ignored by Git; only the `.example` template is versioned.
- A setting in the environment wins over the file, and the command line wins over both.
- An invalid value stops the script with exit code 2 and names the wrong setting.

## The proof folder

The proofs are saved in `ndm_file-timestamp-proofs/` **next to the script** (its real
location, also when it is started through a symbolic link), with one subfolder per run
(UTC date and time), so earlier proofs are never overwritten.

The folder is part of the repository, empty except for a `.gitkeep` file, so you can see
from the start where the proofs will go. Git ignores everything else in it, so your proofs
are never committed and `git pull` never touches them. If the folder is removed, the
script creates it again on the next run. With `-d DIR` the proofs go to `DIR` instead,
with the same layout.

```
NDM_File-Timestamp/
└── ndm_file-timestamp-proofs/
    ├── .gitkeep                       keeps the empty folder in the repository
    ├── project.zip_20261026-062932.log  report of the run, as shown on screen
    └── project.zip_20261026-062932/
        ├── README.txt                 what each file is and how to verify by hand
        ├── file-info.txt              SHA-256, size, dates, script that made the proofs
        ├── project.zip.sha256         SHA-256 checksum, usable with "sha256sum -c"
        ├── project.zip.tsq            RFC 3161 request sent to the TSAs (hash only)
        ├── project.zip.freetsa.tsr    RFC 3161 response = THE TIMESTAMP (keep it!)
        ├── project.zip.freetsa.txt    readable timestamp: look for the "Time stamp" line
        ├── freetsa-certs.pem          certificates needed to verify the .tsr
        ├── freetsa-2151b61137ffa86b.pem  copy of the FreeTSA root, for the manual steps
        ├── freetsa-verify.txt         result of the verification done right away
        └── …                          the same files for digicert and sectigo
                                       (their root certificates come with ca-certificates)
```

Keep in mind:

- **Only the content of the file counts.** Changing a single byte invalidates every
  proof; its name, folder, dates and permissions do not matter (see
  [Copies, moves and archives](#copies-moves-and-archives)).
- **The original file is not copied**: the proofs stay next to the script, the file
  stays where it is. Keep copies of both, in at least two places: `--archive` packs them
  together.
- **The proofs live inside your copy of the repository.** Save the proof folder before
  you delete or move that copy, and include it in your backups.
- **The folder is personal**: it contains the name, size, dates and hash of your file in
  plain text.
- The "Proofs created" line in `file-info.txt` is the local clock of your computer, not a
  proof: the dates that count are those signed by the TSAs.

## Copies, moves and archives

A timestamp covers the **content** of the file, byte for byte, and nothing else. Moving
the file, renaming it, copying it to another disk or computer, changing its dates or
permissions: none of this touches the proofs. `--verify` recognizes a file by its
content, so a renamed copy is verified too, with a note of the name it had when it was
stamped.

The proofs no longer match when the **content** changes, even without your noticing:

- a zip or other archive is re-created, even from the same files;
- line endings are converted (FTP in text mode, some mail programs, editors that
  "fix" the file);
- a cloud service converts the file to its own format, or recompresses images and PDFs;
- the file is opened and saved again (office programs do it even without changes);
- a copy is interrupted or the disk is damaged.

A file whose content has changed cannot be repaired: only an unchanged copy can be
verified. So, after copying the file somewhere else, run `--verify` **on the copy** before
deleting the original.

To keep or move everything together, use `--archive`:

```bash
./ndm_file-timestamp.sh --archive project.zip
```

It verifies the file first: an archive is made only when at least one timestamp is
valid. It creates `project.zip_bundle_<YYYYMMDD>-<HHMMSS>.tar` in
`ndm_file-timestamp-archives/` next to the script (or in `ARCHIVE_DIR`), and next to it
`project.zip_bundle_<YYYYMMDD>-<HHMMSS>.log`, the report of that run as shown on screen
(without colors): which proofs and attachments were valid when the archive was made.
Like the proof folder, that folder is in the repository, empty except for a `.gitkeep`
file: Git ignores the archives, and the script creates the folder again if it is
missing. The archive contains:

```
project.zip_bundle_20261026-065616/
├── project.zip                  the file, byte for byte the one that was timestamped
├── ndm_file-timestamp-proofs/   its proof folders with a valid timestamp, and their logs
├── attachments/                 only with --attach: the documents that go with the file
├── ndm_file-timestamp-certs/    the three TSA roots, so that the archive verifies offline
├── ndm_file-timestamp.sh        this script, which made and verifies the proofs
├── LICENSE                      its license (GNU AGPL v3)
├── SHA256SUMS                   SHA-256 of the file (and attachments) and of the script
└── README.txt                   what the archive contains and how to verify it
```

The documents that go with the file, such as the signed
[declaration of authorship](templates/) or the receipts of a PEC, can travel in the same
archive with `--attach` (one `FILE` per archive, so that it is clear which work they
belong to):

```bash
./ndm_file-timestamp.sh --archive project.zip \
    --attach ndm_file-timestamp-attachments/project/
```

`--attach` takes a file or a folder (the files directly inside it), and can be repeated.
Each attachment is verified like the file: its valid proofs go into the archive too, so
that `./ndm_file-timestamp.sh --verify attachments/declaration.pdf` works in the extracted
folder. Stamp the declaration **before** archiving it: an attachment without valid
timestamps (for example a PEC receipt, which has a value of its own) is packed anyway,
with a warning, and the `README.txt` of the archive says which attachments the
timestamps confirm. Putting a file in the archive does not give it a date: only its own
timestamps do.

The archive is complete: years later, on another computer, extract it and run
`./ndm_file-timestamp.sh --verify project.zip` inside the extracted folder. The proofs
are also verifiable by hand with `openssl`, without the script. The SHA-256 of the
script in `SHA256SUMS` can be compared with the same version published in this
repository.

## Verifying

### With the script

```bash
./ndm_file-timestamp.sh --verify project.zip
```

`--verify` looks for the proofs in the folder next to the script, in `DIR` when given
with `-d`, and in a `ndm_file-timestamp-proofs/` folder in the current directory or next
to the file (for proofs that you moved there, for example together with the file). For
each set of proofs it compares the file's current hash with the saved one (a modified file is reported as **MODIFIED**), checks every timestamp, and ends
with the earliest date proved. It works offline, except the first time it needs the
root certificates (see [Root certificates](#root-certificates)).

Certificates are checked **at the date of each timestamp**. TSA certificates expire
(today's ones between 2037 and 2040): a timestamp signed while its certificate was
valid stays valid afterwards, so old proofs keep verifying.

### By hand

The proofs do not depend on this script: anyone can check them with `openssl`
(`README.txt` in each proof folder repeats these steps):

```bash
P=~/NDM_File-Timestamp/ndm_file-timestamp-proofs/project.zip_20261026-062932
F=~/Documents/project.zip

# 1. The file is unchanged: from the folder that contains it
cd "$(dirname "$F")" && sha256sum -c "$P/project.zip.sha256"

# 2-5: from inside the proof folder
cd "$P"

# 2. The root certificates are the real ones: each SHA-256 must be the one in
#    "Root certificates" above and the one published by the TSA
sha256sum freetsa-*.pem digicert-*.crt sectigo-*.crt

# 3. The timestamp is valid (FreeTSA)
openssl ts -verify -data "$F" -in project.zip.freetsa.tsr \
    -CAfile freetsa-2151b61137ffa86b.pem -untrusted freetsa-certs.pem

# 4. The timestamp is valid (DigiCert; Sectigo the same way, with its .crt):
#    the .crt root is converted to PEM first
openssl x509 -inform DER -in digicert-552f7bdcf1a7af9e.crt -out /tmp/digicert-root.pem
openssl ts -verify -data "$F" -in project.zip.digicert.tsr \
    -CAfile /tmp/digicert-root.pem -untrusted digicert-certs.pem

# 5. The certified date
openssl ts -reply -in project.zip.freetsa.tsr -text | grep 'Time stamp'
```

Step 2 matters: never trust a root certificate only because it is next to the proofs.

The `openssl` commands run from inside the proof folder because openssl splits the
`-untrusted` path at spaces, and the folder is named after the file: a file name with
spaces would break the command.

Each check must end with `Verification: OK`. openssl may also print a warning that the
TSA certificate "is not a CA cert": it is expected and does not affect the result.
If a TSA certificate has expired, add `-attime <epoch>` with the date of the timestamp,
for example `-attime $(date -d "Oct 26 06:29:33 2026 GMT" +%s)`.
On macOS use `shasum -a 256 -c` instead of `sha256sum -c`, and
`date -j -u -f '%b %d %H:%M:%S %Y %Z' "Oct 26 06:29:33 2026 GMT" +%s` for the epoch.

### In the long run

- **Expired certificates do not matter.** `--verify` checks every certificate at the
  date of the timestamp, not today: a timestamp signed while its certificates were valid
  stays valid after they expire (the TSA certificates expire between 2037 and 2041). The
  only exception is the `openssl` of macOS (LibreSSL), which may not support this: the
  script warns about it, and OpenSSL 3 has no such limit (see "Requirements").
- **New roots.** Before a root expires, its TSA moves to a new one. From two years before
  the expiry, stamping shows a warning; when the TSA has moved, new timestamps are still
  saved but reported as leading to no trusted root, until a newer version of the script
  adds the new root. Older timestamps keep verifying, also with the archived script.
- **Stronger algorithms.** In many years RSA or SHA-256 may become weak. The usual
  remedy is to stamp the archive itself again every few years (for example every five,
  or when the script announces a new root): the new timestamp, made with the algorithms of
  its time, covers the archive and the older proofs in it.

  ```bash
  ./ndm_file-timestamp.sh ndm_file-timestamp-archives/project.zip_bundle_20261026-065616.tar
  ```

  Then archive that `.tar` too (`--archive` on it), or keep it with its new proofs.
- **Keep the archives.** Each one holds the script of its time, with its trusted roots, so
  it can be verified on its own; check that script with the independent check in
  [Checking the script](#checking-the-script).

## Checking the script

The script decides whether a proof is valid, so it matters that it is exactly the
published one. There are two checks.

**Independent check (the one that counts).** It does not rely on the script being
checked: compare the SHA-256 of your copy with the file published for its version
(replace `X.Y.Z` with the version shown by `--version`):

```bash
sha256sum ndm_file-timestamp.sh
curl -fsSL https://raw.githubusercontent.com/nidamanx/NDM_File-Timestamp/vX.Y.Z/ndm_file-timestamp.sh | sha256sum
```

The two hashes must be equal (on macOS use `shasum -a 256`). In a clone of the
repository, `git status` and `git diff vX.Y.Z -- ndm_file-timestamp.sh` also show any
local change.

**Built-in check.** `--check-script` makes the same comparison by itself, and
`SCRIPT_CHECK=on` in the configuration file runs it before every stamp, verification or
archive: the script stops if it is different, and only warns when the comparison is not
possible (no network, or a version that is not published). Keep in mind that a script
cannot vouch for itself: whoever modifies it on purpose can also modify this check. It
catches damaged copies and careless edits; against deliberate tampering only the
independent check counts.

After the comparison, `--check-script` (and `SCRIPT_CHECK=on`) also says whether a newer
version has been released, with the link to it and how to update (see
[Updating](#updating)). In a clean git clone, `--check-script` alone also offers to update
it: it asks first, never updates without a terminal, and with `SCRIPT_CHECK=on` it only
shows the notice, so a stamp is never interrupted. This is information only: it never
changes the exit code nor stops a run, and when GitHub cannot be reached it says that it
cannot tell. Like the comparison, a modified script can hide this notice too.

Every proof folder records in `file-info.txt` the SHA-256 of the script that made it, and
every archive made with `--archive` contains the script with its SHA-256 in `SHA256SUMS`.

## Sample output

> **Note:** this output is only an illustration, from a test file. Hashes, dates and
> paths change at every run, and the layout may change between versions.

Creating the proofs:

```bash
./ndm_file-timestamp.sh project.zip
```

```
==> Output folder: /home/user/NDM_File-Timestamp/ndm_file-timestamp-proofs/project.zip_20261026-062932
==> SHA-256: ad73101d6844ad9f09596e2e46bec9da435d2697c93107b5ce049a9720538f11
==> 1/3 freetsa (https://freetsa.org/tsr)
==>     OK - Time stamp: Oct 26 06:29:33 2026 GMT - verified
==> 2/3 digicert (http://timestamp.digicert.com)
==>     OK - Time stamp: Oct 26 06:29:34 2026 GMT - verified
==> 3/3 sectigo (http://timestamp.sectigo.com)
==>     OK - Time stamp: Oct 26 06:29:35 2026 GMT - verified

==> Summary for project.zip
    freetsa   Time stamp: Oct 26 06:29:33 2026 GMT - verified
    digicert  Time stamp: Oct 26 06:29:34 2026 GMT - verified
    sectigo   Time stamp: Oct 26 06:29:35 2026 GMT - verified
```

Verifying:

```bash
./ndm_file-timestamp.sh --verify project.zip
```

```
==> File:    /home/user/docs/project.zip
==> SHA-256: ad73101d6844ad9f09596e2e46bec9da435d2697c93107b5ce049a9720538f11

==> Proofs: project.zip_20261026-062932
    digicert  VALID     2026-10-26 06:29:34 UTC  (local time: 2026-10-26 07:29:34 CET)
    freetsa   VALID     2026-10-26 06:29:33 UTC  (local time: 2026-10-26 07:29:33 CET)
    sectigo   VALID     2026-10-26 06:29:35 UTC  (local time: 2026-10-26 07:29:35 CET)

==> Result: project.zip existed, unchanged, at least since
    26/10/2026 07:29:33 CET  (freetsa)
    confirmed by 3 valid timestamp(s)
```

## Legal value

These timestamps are **technical evidence**: they show, with standard cryptography, that
a file with that exact hash existed no later than the certified date. How much weight
they carry is up to whoever assesses them, for example a judge.

**What they are for.** In most countries (those party to the Berne Convention)
copyright arises when a work is created, with no registration, but it has to be proved.
If someone copies your text, program, book, image, video or project and presents it as
their own, a timestamp earlier than their publication is strong evidence that the work
already existed, in that exact form, at an earlier date. It is free, immediate and can
be repeated for every version of the work: it does not carry the weight of an official
registration, but it is far better than no evidence at all, because without dated
evidence it is only your word against that of whoever copied the work.

**What they do not prove.**

- **Who** made the file: a timestamp holds only the hash, no name, and anyone with a
  copy can stamp it. Authorship is shown by other means, which the timestamp supports:
  original working files, earlier drafts (stamp those too, as the work grows), public
  captures (for example the Internet Archive), a signed declaration (template in
  [templates/](templates/), in English and Italian; see
  [Protecting a work, step by step](#protecting-a-work-step-by-step)).
- The date of **creation**: only that the file existed by that date.
- A file that **differs** from the stamped one, even slightly (see
  [Copies, moves and archives](#copies-moves-and-archives)): keep the original.
- They give no rights beyond those the law already gives: they do not protect ideas and
  do not replace a patent or a trademark.

**When stronger protection is needed.** None of the three TSAs is a **qualified** trust
service provider under the EU eIDAS regulation: their timestamps are admissible as
evidence, but they lack the legal presumption of an accurate date that qualified
timestamps have, and in Italy they do not give *data certa* in the strict legal sense.
For works of significant value, use the script **together with** a tool that has full
legal value in your country, for example:

- a **qualified** timestamp (EU) from a provider on the EU trusted lists;
- in Italy, a **PEC** (certified e-mail) with the file attached (also to yourself): keep
  the message and its receipts (Italian template of the text in
  [templates/](templates/));
- deposit or registration with the body of your country (in Italy **SIAE**, for
  unpublished works; in the United States the U.S. Copyright Office; elsewhere the
  national copyright office);
- a notarial deed or a deposit with a notary.

This is general information, not legal advice: in case of a dispute, consult a lawyer.

## External services contacted

| Service | Used for | What it receives |
|---------|----------|------------------|
| FreeTSA (`freetsa.org`, HTTPS) | Timestamp; once, download of its root certificate | The SHA-256 hash (nothing for the certificate) |
| DigiCert (`timestamp.digicert.com`, HTTP) | Timestamp | The SHA-256 hash |
| Sectigo (`timestamp.sectigo.com`, HTTP) | Timestamp | The SHA-256 hash |
| DigiCert (`cacerts.digicert.com`) and Sectigo (`crt.usertrust.com`), HTTP | Once, download of their root certificates | Nothing |
| GitHub (`raw.githubusercontent.com`, HTTPS) | Only `--check-script` and `SCRIPT_CHECK=on`: download of the published script | Nothing about your files |
| GitHub (`github.com`, HTTPS) | Only `--check-script` and `SCRIPT_CHECK=on`: number of the latest version (`/releases/latest`) | Nothing about your files |

Nothing else is sent: not the file, not its name. As with any web request, the services
see the IP address of your computer. `--verify`, `--list`, `--archive`, `--requirements`,
`--version` and `--help` contact no service (unless `SCRIPT_CHECK=on`), except the one
download of the root certificates when they are not there yet (also with `--verify`,
`--archive` and `--get-certs`). Every download is limited to 30 seconds and 1 MB.

## Exit codes

| Code | Meaning |
|:----:|---------|
| `0` | Every file got at least one verified timestamp (`MIN_TIMESTAMPS`), or `--verify` found at least one valid timestamp for the current content of every file, or `--archive` archived every file; `--list` always; `--verify-certs`: all the root certificates are there and unaltered |
| `1` | A file got fewer verified timestamps than `MIN_TIMESTAMPS` (for example no network) or, with `--verify`, has no valid timestamp for its current content (for example because it was modified); with `--archive`, a file without valid timestamps (no archive is made); a file or an attachment not found or not readable, a missing tool, or missing root certificates (download declined or failed; `--get-certs`, `--verify-certs`) |
| `2` | Invalid command-line usage (unknown option, missing or extra argument), or an invalid setting in the configuration file or the environment |

This makes the script usable from other scripts.

## Project layout

```
NDM_File-Timestamp/
├── ndm_file-timestamp.sh          the script
├── ndm_file-timestamp-files/      suggested place for your files to stamp (ignored by Git)
│   └── .gitkeep                   keeps the empty folder in the repository
├── ndm_file-timestamp-attachments/  their declarations and receipts (ignored by Git)
│   └── .gitkeep                   keeps the empty folder in the repository
├── ndm_file-timestamp-certs/      TSA root certificates, downloaded and checked once (ignored by Git)
│   └── .gitkeep                   keeps the empty folder in the repository
├── ndm_file-timestamp-proofs/     your proofs (contents ignored by Git)
│   └── .gitkeep                   keeps the empty folder in the repository
├── ndm_file-timestamp-archives/   your archives made with --archive, and their logs (ignored by Git)
│   └── .gitkeep                   keeps the empty folder in the repository
├── templates/                     blank templates to fill in (see the step-by-step section)
│   ├── authorship-declaration.en.txt  declaration of authorship of a work, in English
│   ├── authorship-declaration.it.txt  the same in Italian
│   └── pec-message.it.txt         text of a PEC message (Italy)
├── ndm_file-timestamp.conf.example  configuration template (versioned)
├── ndm_file-timestamp.conf        your configuration (personal, ignored by Git)
├── .github/workflows/ci.yml       automatic checks (ShellCheck, version, tests on Linux and macOS)
├── .github/dependabot.yml         monthly updates of the GitHub Actions used by CI
├── .gitattributes                 keeps Linux line endings (needed on Windows)
├── .gitignore                     keeps your files, attachments, proofs and archives out of Git
├── LICENSE                        GNU AGPL v3
├── CHANGELOG.md                   changes in each version
├── CITATION.cff                   how to cite this software (used by GitHub)
├── SECURITY.md                    how to report a vulnerability
├── README.md                      documentation in English
├── README.it.md                   documentation in Italian
├── QUICKSTART.md                  step-by-step guide with an example, in English
└── QUICKSTART.it.md               the same in Italian
```

## Versioning

The project follows [Semantic Versioning](https://semver.org/). Name, description,
author, version and release date are in the **APP INFO** block at the very top of
`ndm_file-timestamp.sh`; `--version` shows them. Every release has a Git tag `vX.Y.Z`,
and the changes of each version are listed in [CHANGELOG.md](CHANGELOG.md).

## License and disclaimer

Copyright (C) 2023-2026 Nicola Davide Mannarelli ([@nidamanx](https://github.com/nidamanx))

This program is free software: you can redistribute it and/or modify it under the
terms of the **GNU Affero General Public License** as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later version
(`SPDX-License-Identifier: AGPL-3.0-or-later`). See the [LICENSE](LICENSE) file.

**Credit.** If you use this tool, or parts of its code, in your work or in another
project, please credit *NDM File Timestamp* by Nicola Davide Mannarelli and link to this
repository. The **Cite this repository** button on GitHub, generated from
[CITATION.cff](CITATION.cff), gives a ready-made citation. The license already requires
redistributed and modified copies to keep the copyright notice.

**Disclaimer.** This software is provided "as is", without warranty of any kind,
express or implied. In no event shall the author be liable for any claim, damages or
other liability, including loss of data, timestamps not obtained, proofs that cannot be
verified or that are not accepted as evidence, arising from the use or misuse of this
software. You alone are responsible for how you use it, for keeping your files and their
proofs, and for any decision taken on the basis of its results.
