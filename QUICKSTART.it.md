# Guida rapida

[English](QUICKSTART.md) · **Italiano**

> Traduzione di [QUICKSTART.md](QUICKSTART.md): in caso di differenze prevale la versione
> inglese.

Dall'inizio alla fine, con un esempio. Lo script funziona con **qualsiasi file
digitale**: codice sorgente, un archivio di release, un eseguibile, il dump di un
database, immagini, video, musica, documenti, progetti grafici. I passi qui sotto sono
gli stessi per tutti.

**L'esempio usato qui:** hai scritto un romanzo, `romanzo.pdf`, e vuoi poter
dimostrare, tra anni, che esisteva oggi in questa forma esatta. Per il tuo lavoro
sostituisci `romanzo.pdf` con il tuo file e `romanzo/` con una cartella che porta il suo
nome. Tutta la procedura richiede circa dieci minuti. I dettagli su ogni opzione sono
nel [README](README.it.md).

> **Per il software:** marca un unico file che contiene l'intera versione, per esempio
> l'archivio di release (`git archive --format=zip -o myapp-1.2.0.zip v1.2.0`) o uno zip
> dei sorgenti, e conserva proprio quel file: uno zip ricreato in seguito, anche dallo
> stesso commit, può differire di qualche byte e non corrispondere più alle sue prove.
> Una cartella non si può marcare direttamente: va prima raccolta in un unico file.

> **Nota:** l'output mostrato qui viene da un'esecuzione reale su un file di prova; sono
> stati accorciati solo i percorsi. Hash e date cambiano a ogni esecuzione.

## 1. Installa lo script e controlla i requisiti

Su Linux o macOS (su Windows, installa prima WSL: vedi
[Windows (WSL)](README.it.md#windows-wsl)):

```bash
git clone https://github.com/nidamanx/NDM_File-Timestamp.git
cd NDM_File-Timestamp
./ndm_file-timestamp.sh --requirements
```

L'ultima riga deve essere `Everything is installed.`; altrimenti lo script mostra il
comando che installa ciò che manca.

## 2. Metti l'opera nella cartella dei file

Copia il file in `ndm_file-timestamp-files/` (Git lo ignora, quindi non viene mai
pubblicato per sbaglio):

```bash
cp ~/Documents/romanzo.pdf ndm_file-timestamp-files/
```

Da qui in poi **non aprire e non risalvare questa copia**: basta un byte diverso e le
prove non corrispondono più. Continua a lavorare sull'originale in `~/Documents`.

## 3. Marca l'opera

```bash
./ndm_file-timestamp.sh ndm_file-timestamp-files/romanzo.pdf
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

==> Output folder: /home/user/NDM_File-Timestamp/ndm_file-timestamp-proofs/romanzo.pdf_20261026-164702
==> SHA-256: 91e38e78b752840bb5d673b553175cc080fa126980a9b7e58f065ffc691b8578
==> 1/3 freetsa (https://freetsa.org/tsr)
==>     OK - Time stamp: Oct 26 16:47:02 2026 GMT - verified
==> 2/3 digicert (http://timestamp.digicert.com)
==>     OK - Time stamp: Oct 26 16:47:03 2026 GMT - verified
==> 3/3 sectigo (http://timestamp.sectigo.com)
==>     OK - Time stamp: Oct 26 16:47:03 2026 GMT - verified

==> Summary for romanzo.pdf
    freetsa   Time stamp: Oct 26 16:47:02 2026 GMT - verified
    digicert  Time stamp: Oct 26 16:47:03 2026 GMT - verified
    sectigo   Time stamp: Oct 26 16:47:03 2026 GMT - verified
```

Tre autorità indipendenti hanno firmato l'hash del file con la loro data. È stato inviato
solo l'hash, mai il file.

**Solo la prima volta**, prima di tutto il resto, lo script chiede di scaricare i
certificati radice delle tre TSA, che gli servono per controllarne le firme. Rispondi `y`
(o premi semplicemente Invio): per ognuno mostra lo SHA-256 atteso e quello ottenuto, e
lo conserva in `ndm_file-timestamp-certs/` solo se coincidono. Non viene più chiesto. Se
rispondi `n`, lo script si ferma: senza di essi nessuna marca si potrebbe verificare. Puoi anche farlo
prima con `--get-certs`, oppure a mano: vedi
[Certificati radice](README.it.md#certificati-radice).

## 4. Verifica e annota il risultato

```bash
./ndm_file-timestamp.sh --verify ndm_file-timestamp-files/romanzo.pdf
```

```
==> File:    /home/user/NDM_File-Timestamp/ndm_file-timestamp-files/romanzo.pdf
==> SHA-256: 91e38e78b752840bb5d673b553175cc080fa126980a9b7e58f065ffc691b8578

==> Proofs: romanzo.pdf_20261026-164702
    digicert  VALID     2026-10-26 16:47:03 UTC  (local time: 2026-10-26 17:47:03 CET)
    freetsa   VALID     2026-10-26 16:47:02 UTC  (local time: 2026-10-26 17:47:02 CET)
    sectigo   VALID     2026-10-26 16:47:03 UTC  (local time: 2026-10-26 17:47:03 CET)

==> Result: romanzo.pdf existed, unchanged, at least since
    26/10/2026 17:47:02 CET  (freetsa)
    confirmed by 3 valid timestamp(s)
```

Annota lo **SHA-256** e la data **"at least since"** ("esiste almeno dal"): vanno nella
dichiarazione.

## 5. Compila e firma la dichiarazione di paternità

```bash
mkdir ndm_file-timestamp-attachments/romanzo
cp templates/authorship-declaration.it.txt ndm_file-timestamp-attachments/romanzo/dichiarazione.txt
```

Apri `dichiarazione.txt`, cancella il riquadro di istruzioni in cima, sostituisci ogni
`[SEGNAPOSTO]` (i tuoi dati, il titolo, lo SHA-256 e la data del passo 4) e firmala:

- a mano: stampala, firmala, scansionala come `ndm_file-timestamp-attachments/romanzo/dichiarazione.pdf`;
- meglio, con una firma digitale, che produce un `dichiarazione.pdf` firmato (o un `.p7m`).

Poi cancella `dichiarazione.txt`: nella cartella resta solo il documento firmato.

## 6. Marca la dichiarazione firmata

```bash
./ndm_file-timestamp.sh ndm_file-timestamp-attachments/romanzo/dichiarazione.pdf
```

```
==> Output folder: /home/user/NDM_File-Timestamp/ndm_file-timestamp-proofs/dichiarazione.pdf_20261026-164704
==> SHA-256: 5dab8a38f1795ee1447487ec1aedb37435868345edbe896c71c7c907bd80e778
==> 1/3 freetsa (https://freetsa.org/tsr)
==>     OK - Time stamp: Oct 26 16:47:05 2026 GMT - verified
==> 2/3 digicert (http://timestamp.digicert.com)
==>     OK - Time stamp: Oct 26 16:47:05 2026 GMT - verified
==> 3/3 sectigo (http://timestamp.sectigo.com)
==>     OK - Time stamp: Oct 26 16:47:07 2026 GMT - verified

==> Summary for dichiarazione.pdf
    freetsa   Time stamp: Oct 26 16:47:05 2026 GMT - verified
    digicert  Time stamp: Oct 26 16:47:05 2026 GMT - verified
    sectigo   Time stamp: Oct 26 16:47:07 2026 GMT - verified
```

La dichiarazione contiene lo SHA-256 del romanzo, quindi le due prove si sostengono a
vicenda. Ora `--list` le mostra entrambe:

```bash
./ndm_file-timestamp.sh --list
```

```
==> Proofs in /home/user/NDM_File-Timestamp/ndm_file-timestamp-proofs
    Run (UTC)            Timestamps  SHA-256 (start)   File
    2026-10-26 16:47:02  3           91e38e78b752840b  romanzo.pdf
    2026-10-26 16:47:04  3           5dab8a38f1795ee1  dichiarazione.pdf

    2 proof folder(s). The run dates come from the local clock; the dates
    that count are those signed by the TSAs: see them with --verify FILE.
```

## 7. Facoltativo: una tutela legale più forte

Per un'opera di valore importante aggiungi uno strumento con pieno valore legale: in
Italia una PEC (testo pronto in `templates/pec-message.it.txt`) o il deposito SIAE; in
generale una marca temporale qualificata (UE), un deposito presso un notaio o la
registrazione presso l'ufficio del diritto d'autore del tuo paese. Salva le ricevute
anche in `ndm_file-timestamp-attachments/romanzo/`: il passo successivo le raccoglie
con il resto. Vedi [Valore legale](README.it.md#valore-legale).

## 8. Raccogli tutto in un unico archivio

```bash
./ndm_file-timestamp.sh --archive ndm_file-timestamp-files/romanzo.pdf \
    --attach ndm_file-timestamp-attachments/romanzo/
```

Lo script verifica il romanzo e ogni allegato, poi crea l'archivio (il resoconto della
verifica, uguale a quello del passo 4, qui è accorciato):

```
...
==> Attachment 1 of 1
==> File:    /home/user/NDM_File-Timestamp/ndm_file-timestamp-attachments/romanzo/dichiarazione.pdf
...
==> Result: dichiarazione.pdf existed, unchanged, at least since
    26/10/2026 17:47:05 CET  (digicert)
    confirmed by 3 valid timestamp(s)

==> Archive: /home/user/NDM_File-Timestamp/ndm_file-timestamp-archives/romanzo.pdf_bundle_20261026-164707.tar
    romanzo.pdf, 1 proof folder(s), ndm_file-timestamp.sh 1.5.0 and its LICENSE.
    attachments/: 1 file(s), 1 with valid timestamps.
    To check it later: extract it, then run in the extracted folder
      ./ndm_file-timestamp.sh --verify "romanzo.pdf"
      ./ndm_file-timestamp.sh --verify "attachments/dichiarazione.pdf"
```

Il `.tar` contiene il romanzo, la dichiarazione, le loro prove, i certificati radice delle
TSA, questo script e la sua licenza: tutto il necessario per verificare, su qualunque
computer, anche senza rete e senza questo repository.

## 9. Conservalo in due posti e controlla le copie

Copia l'archivio in almeno due posti (per esempio un disco esterno e uno spazio cloud),
poi controlla una copia, come farebbe chiunque altro:

```bash
cp ndm_file-timestamp-archives/romanzo.pdf_bundle_*.tar /media/backup/
cd /media/backup
tar -xf romanzo.pdf_bundle_20261026-164707.tar
cd romanzo.pdf_bundle_20261026-164707
sha256sum -c SHA256SUMS
./ndm_file-timestamp.sh --verify romanzo.pdf
./ndm_file-timestamp.sh --verify attachments/dichiarazione.pdf
```

```
romanzo.pdf: OK
attachments/dichiarazione.pdf: OK
ndm_file-timestamp.sh: OK
==> File:    /media/backup/romanzo.pdf_bundle_20261026-164707/romanzo.pdf
...
==> Result: romanzo.pdf existed, unchanged, at least since
    26/10/2026 17:47:02 CET  (freetsa)
    confirmed by 3 valid timestamp(s)
==> File:    /media/backup/romanzo.pdf_bundle_20261026-164707/attachments/dichiarazione.pdf
...
==> Result: dichiarazione.pdf existed, unchanged, at least since
    26/10/2026 17:47:05 CET  (digicert)
    confirmed by 3 valid timestamp(s)
```

Su macOS usa `shasum -a 256 -c SHA256SUMS`. Dopo il controllo la cartella estratta si
può cancellare: conserva il `.tar`.

## 10. In seguito

- **Una nuova versione dell'opera?** Ripeti dal passo 2 con il nuovo file: ogni versione
  ha le sue prove, e le bozze aiutano a provare la paternità.
- **Qualcuno copia l'opera?** Consegna l'archivio (`.tar`) al tuo legale o al perito: il
  suo `README.txt` spiega cosa contiene e come verificarlo, con lo script o a mano con
  `openssl`, senza doversi fidare di questo script. La data dimostrata è quella "at least
  since".
- **Ogni qualche anno?** Marca di nuovo l'archivio stesso (per esempio ogni cinque anni,
  o quando lo script annuncia una nuova radice), così le marche nuove coprono quelle
  vecchie: vedi [Nel lungo periodo](README.it.md#nel-lungo-periodo).
- **Cambi computer?** Copia gli archivi, e la cartella `ndm_file-timestamp-proofs/` se
  vuoi continuare a marcare e verificare anche lì.
