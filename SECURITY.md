# Security Policy

## Supported versions

Only the latest release receives fixes.

| Version | Supported |
| ------- | --------- |
| latest  | yes       |
| older   | no        |

## Reporting a vulnerability

Please **do not open a public issue** for security problems.

Use GitHub's private reporting instead: open the **Security** tab of this
repository and click **Report a vulnerability**. You will get a private
channel with the maintainer.

Useful details to include:

- script version (`./ndm_file-timestamp.sh --version`) and the output of
  `./ndm_file-timestamp.sh --requirements`;
- operating system;
- steps to reproduce, using a throw-away test file, never a file of yours that must
  stay private: the proof folders contain its name and SHA-256 hash;
- the impact you expect (for example "command injection" or "a modified file reported
  as valid").

## What is in scope

- Unsafe handling of the file name, command-line options, configuration file or
  environment (code execution, injection, writing outside the proof and archive folders,
  overwriting earlier proofs). The configuration file must only be read, never executed.
- `--check-script` or `SCRIPT_CHECK=on` reporting a script as identical to the published
  one when it is not, for a script that was not itself modified to lie.
- Data sent over the network other than the SHA-256 hash of the file, or sent to
  services other than the three Time Stamping Authorities listed in the help, the
  download of their root certificates and, only with `--check-script` or
  `SCRIPT_CHECK=on`, the published script on GitHub.
- `--verify` reporting a timestamp as valid when the file was modified, when the
  signature or the certificate chain is not valid, or when the response was not
  granted by the TSA.
- `--verify` trusting a root certificate that comes with the proofs (a proof folder or
  an archive) instead of the ones listed in the script (`TSA_ROOTS`), a root whose
  SHA-256 is not the listed one, or the root of one TSA for a timestamp named after
  another.
- A wrong "earliest date proved", or a date taken from the local clock instead of a
  timestamp signed by a TSA.
- Responses that make the script hang indefinitely or fill the disk.

## What is out of scope

- Content of the proof folders: they hold your file's name, size, dates and hash in
  plain text; protecting them is up to you.
- Availability or correctness of the Time Stamping Authorities, and the security of
  their keys and certificates.
- Plain HTTP towards DigiCert and Sectigo: it is normal for RFC 3161, because every
  response is digitally signed and checked, so it cannot be altered without detection.
- The legal value of the proofs: these TSAs are not qualified eIDAS providers, as
  stated in the help.
- A deliberately modified script that passes its own `--check-script`: a script cannot
  vouch for itself. The README describes the independent check for this case.

## Disclosure

This is a personal project maintained on a best-effort basis. Reports are
acknowledged as soon as reasonably possible and fixes are released before any
public disclosure.
