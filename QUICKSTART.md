# Quick start

**English** · [Italiano](QUICKSTART.it.md)

From the beginning to the end, with one example. The script works with **any digital
file**: source code, a release archive, a binary, a database dump, images, video, music,
documents, designs. The steps below are the same for all of them.

**The example used here:** you have written a novel, `novel.pdf`, and you want to be
able to prove, years from now, that it existed in this exact form today. For your own
work, replace `novel.pdf` with your file and `novel/` with a folder named after it. The
whole procedure takes about ten minutes. Details on every option are in the
[README](README.md).

> **For software:** stamp a single file that contains the whole version, for example the
> release archive (`git archive --format=zip -o myapp-1.2.0.zip v1.2.0`) or a zip of the
> sources, and keep that exact file: a zip created again later, even from the same
> commit, may differ by a few bytes and no longer match its proofs. A folder cannot be
> stamped directly: pack it into one file first.

> **Note:** the output shown here comes from a real run on a test file; only the paths
> were shortened. Hashes and dates change at every run.

## 1. Install the script and check the requirements

On Linux or macOS (on Windows, first install WSL: see
[Windows (WSL)](README.md#windows-wsl)):

```bash
git clone https://github.com/nidamanx/NDM_File-Timestamp.git
cd NDM_File-Timestamp
./ndm_file-timestamp.sh --requirements
```

The last line must be `Everything is installed.`; otherwise the script shows the command
that installs what is missing.

## 2. Put the work in the files folder

Copy the file into `ndm_file-timestamp-files/` (Git ignores it, so it is never
published by mistake):

```bash
cp ~/Documents/novel.pdf ndm_file-timestamp-files/
```

From now on **do not open and save this copy again**: a single different byte and the
proofs no longer match. Keep working on the original in `~/Documents`.

## 3. Stamp the work

```bash
./ndm_file-timestamp.sh ndm_file-timestamp-files/novel.pdf
```

```
!!  Root certificates are needed to verify the timestamps, and these are not in
!!      /home/user/NDM_File-Timestamp/ndm_file-timestamp-certs/
!!      freetsa   https://freetsa.org/files/cacert.pem
!!                SHA-256 2151b61137ffa86bf664691ba67e7da0b19f98c758e3d228d5d8ebf27e044438
!!      digicert  http://cacerts.digicert.com/DigiCertTrustedRootG4.crt
!!                SHA-256 552f7bdcf1a7af9e6ce672017f4f12abf77240c78e761ac203d1d9d20ac89988
!!      sectigo   http://crt.usertrust.com/USERTrustRSACertificationAuthority.crt
!!                SHA-256 e793c9b02fd8aa13e21c31228accb08119643b749c898964b1746d46c3d4cbd2
!!      Each one is kept only if its SHA-256 is the value above, which you can compare
!!      with the one the TSA publishes. You can also download and check them by hand
!!      (README.md, "Root certificates") or with --get-certs.
Download and check them now? [Y/n] y
==> Root certificate of freetsa: https://freetsa.org/files/cacert.pem
    expected SHA-256: 2151b61137ffa86bf664691ba67e7da0b19f98c758e3d228d5d8ebf27e044438
    obtained SHA-256: 2151b61137ffa86bf664691ba67e7da0b19f98c758e3d228d5d8ebf27e044438
    same as expected
    saved as ndm_file-timestamp-certs/freetsa-2151b61137ffa86b.pem
==> Root certificate of digicert: http://cacerts.digicert.com/DigiCertTrustedRootG4.crt
    expected SHA-256: 552f7bdcf1a7af9e6ce672017f4f12abf77240c78e761ac203d1d9d20ac89988
    obtained SHA-256: 552f7bdcf1a7af9e6ce672017f4f12abf77240c78e761ac203d1d9d20ac89988
    same as expected
    saved as ndm_file-timestamp-certs/digicert-552f7bdcf1a7af9e.crt
==> Root certificate of sectigo: http://crt.usertrust.com/USERTrustRSACertificationAuthority.crt
    expected SHA-256: e793c9b02fd8aa13e21c31228accb08119643b749c898964b1746d46c3d4cbd2
    obtained SHA-256: e793c9b02fd8aa13e21c31228accb08119643b749c898964b1746d46c3d4cbd2
    same as expected
    saved as ndm_file-timestamp-certs/sectigo-e793c9b02fd8aa13.crt

==> Output folder: /home/user/NDM_File-Timestamp/ndm_file-timestamp-proofs/novel.pdf_20261026-164654
==> SHA-256: bb195ed247f51ec1f299ae5053bebc94cb014a9d5ae2ef7012e9645494ea6d42
==> 1/3 freetsa (https://freetsa.org/tsr)
==>     OK - Time stamp: Oct 26 16:46:54 2026 GMT - verified
==> 2/3 digicert (http://timestamp.digicert.com)
==>     OK - Time stamp: Oct 26 16:46:55 2026 GMT - verified
==> 3/3 sectigo (http://timestamp.sectigo.com)
==>     OK - Time stamp: Oct 26 16:46:55 2026 GMT - verified

==> Summary for novel.pdf
    freetsa   Time stamp: Oct 26 16:46:54 2026 GMT - verified
    digicert  Time stamp: Oct 26 16:46:55 2026 GMT - verified
    sectigo   Time stamp: Oct 26 16:46:55 2026 GMT - verified
```

Three independent authorities have signed the hash of the file with their date. Only
the hash was sent, never the file.

**Only the first time**, before anything else, the script asks to download the root
certificates of the three TSAs, which it needs to check their signatures. Answer `y` (or
just press Enter): for each one it shows the expected and the obtained SHA-256, and keeps
it in `ndm_file-timestamp-certs/` only if they match. It is never asked again. If you
answer `n`, the script stops: without them no timestamp could be verified. You can also do
it beforehand with `--get-certs`, or by hand: see
[Root certificates](README.md#root-certificates).

## 4. Verify it and note the result

```bash
./ndm_file-timestamp.sh --verify ndm_file-timestamp-files/novel.pdf
```

```
==> File:    /home/user/NDM_File-Timestamp/ndm_file-timestamp-files/novel.pdf
==> SHA-256: bb195ed247f51ec1f299ae5053bebc94cb014a9d5ae2ef7012e9645494ea6d42

==> Proofs: novel.pdf_20261026-164654
    digicert  VALID     2026-10-26 16:46:55 UTC  (local time: 2026-10-26 17:46:55 CET)
    freetsa   VALID     2026-10-26 16:46:54 UTC  (local time: 2026-10-26 17:46:54 CET)
    sectigo   VALID     2026-10-26 16:46:55 UTC  (local time: 2026-10-26 17:46:55 CET)

==> Result: novel.pdf existed, unchanged, at least since
    26/10/2026 17:46:54 CET  (freetsa)
    confirmed by 3 valid timestamp(s)
```

Note the **SHA-256** and the **"at least since"** date: they go into the declaration.

## 5. Fill in and sign the declaration of authorship

```bash
mkdir ndm_file-timestamp-attachments/novel
cp templates/authorship-declaration.en.txt ndm_file-timestamp-attachments/novel/declaration.txt
```

Open `declaration.txt`, delete the instructions box at the top, replace every
`[PLACEHOLDER]` (your details, title, the SHA-256 and the date of step 4) and sign it:

- by hand: print it, sign it, scan it as `ndm_file-timestamp-attachments/novel/declaration.pdf`;
- better, with a digital signature, which gives a signed `declaration.pdf` (or `.p7m`).

Then delete `declaration.txt`: only the signed document stays in the folder.

## 6. Stamp the signed declaration

```bash
./ndm_file-timestamp.sh ndm_file-timestamp-attachments/novel/declaration.pdf
```

```
==> Output folder: /home/user/NDM_File-Timestamp/ndm_file-timestamp-proofs/declaration.pdf_20261026-164656
==> SHA-256: ecd65e790c3569c337b0fa7f01933d67baa5ba9c964f525f80f3c466ac81f147
==> 1/3 freetsa (https://freetsa.org/tsr)
==>     OK - Time stamp: Oct 26 16:46:57 2026 GMT - verified
==> 2/3 digicert (http://timestamp.digicert.com)
==>     OK - Time stamp: Oct 26 16:46:57 2026 GMT - verified
==> 3/3 sectigo (http://timestamp.sectigo.com)
==>     OK - Time stamp: Oct 26 16:46:59 2026 GMT - verified

==> Summary for declaration.pdf
    freetsa   Time stamp: Oct 26 16:46:57 2026 GMT - verified
    digicert  Time stamp: Oct 26 16:46:57 2026 GMT - verified
    sectigo   Time stamp: Oct 26 16:46:59 2026 GMT - verified
```

The declaration contains the SHA-256 of the novel, so the two proofs support each other.
`--list` now shows both:

```bash
./ndm_file-timestamp.sh --list
```

```
==> Proofs in /home/user/NDM_File-Timestamp/ndm_file-timestamp-proofs
    Run (UTC)            Timestamps  SHA-256 (start)   File
    2026-10-26 16:46:54  3           bb195ed247f51ec1  novel.pdf
    2026-10-26 16:46:56  3           ecd65e790c3569c3  declaration.pdf

    2 proof folder(s). The run dates come from the local clock; the dates
    that count are those signed by the TSAs: see them with --verify FILE.
```

## 7. Optional: stronger legal protection

For a work of significant value, add a tool with full legal value in your country:
registration with the national copyright office, a deposit with a notary, a qualified
timestamp (EU); in Italy a PEC (ready-made text in `templates/pec-message.it.txt`) or
SIAE. Save the receipts in `ndm_file-timestamp-attachments/novel/` too: the next step
packs them with the rest. See [Legal value](README.md#legal-value).

## 8. Pack everything in one archive

```bash
./ndm_file-timestamp.sh --archive ndm_file-timestamp-files/novel.pdf \
    --attach ndm_file-timestamp-attachments/novel/
```

The script verifies the novel and every attachment, then creates the archive (the
verification report, the same as in step 4, is shortened here):

```
...
==> Attachment 1 of 1
==> File:    /home/user/NDM_File-Timestamp/ndm_file-timestamp-attachments/novel/declaration.pdf
...
==> Result: declaration.pdf existed, unchanged, at least since
    26/10/2026 17:46:57 CET  (digicert)
    confirmed by 3 valid timestamp(s)

==> Archive: /home/user/NDM_File-Timestamp/ndm_file-timestamp-archives/novel.pdf_bundle_20261026-164700.tar
    novel.pdf, 1 proof folder(s), ndm_file-timestamp.sh 1.5.0 and its LICENSE.
    attachments/: 1 file(s), 1 with valid timestamps.
    To check it later: extract it, then run in the extracted folder
      ./ndm_file-timestamp.sh --verify "novel.pdf"
      ./ndm_file-timestamp.sh --verify "attachments/declaration.pdf"
```

The `.tar` holds the novel, the declaration, their proofs, the root certificates of the
TSAs, this script and its license: everything needed to verify, on any computer, even
offline and without this repository.

## 9. Keep it in two places, and check the copies

Copy the archive to at least two places (for example an external disk and a cloud
storage), then check a copy, as someone else would:

```bash
cp ndm_file-timestamp-archives/novel.pdf_bundle_*.tar /media/backup/
cd /media/backup
tar -xf novel.pdf_bundle_20261026-164700.tar
cd novel.pdf_bundle_20261026-164700
sha256sum -c SHA256SUMS
./ndm_file-timestamp.sh --verify novel.pdf
./ndm_file-timestamp.sh --verify attachments/declaration.pdf
```

```
novel.pdf: OK
attachments/declaration.pdf: OK
ndm_file-timestamp.sh: OK
==> File:    /media/backup/novel.pdf_bundle_20261026-164700/novel.pdf
...
==> Result: novel.pdf existed, unchanged, at least since
    26/10/2026 17:46:54 CET  (freetsa)
    confirmed by 3 valid timestamp(s)
==> File:    /media/backup/novel.pdf_bundle_20261026-164700/attachments/declaration.pdf
...
==> Result: declaration.pdf existed, unchanged, at least since
    26/10/2026 17:46:57 CET  (digicert)
    confirmed by 3 valid timestamp(s)
```

On macOS use `shasum -a 256 -c SHA256SUMS`. The extracted folder can be deleted
afterwards: keep the `.tar`.

## 10. Later

- **A new version of the work?** Repeat from step 2 with the new file: every version gets
  its own proofs, and the drafts help to prove authorship.
- **Someone copies the work?** Hand the archive (`.tar`) to your lawyer or to the
  expert: its `README.txt` explains what it contains and how to verify it, with the
  script or by hand with `openssl`, without trusting this script. The date proved is the
  "at least since" one.
- **Every few years?** Stamp the archive itself again (for example every five years, or
  when the script announces a new root), so that new timestamps cover the older ones:
  see [In the long run](README.md#in-the-long-run).
- **Moving to another computer?** Copy the archives, and the `ndm_file-timestamp-proofs/`
  folder if you want to keep stamping and verifying there.
