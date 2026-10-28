# NDM File Timestamp

[English](README.md) · **Italiano**

[![License: AGPL v3+](https://img.shields.io/badge/License-AGPL_v3%2B-blue.svg)](LICENSE)
![Version](https://img.shields.io/badge/version-1.5.0-informational)
![Shell](https://img.shields.io/badge/shell-bash-4EAA25)

**NDM File Timestamp** dimostra che un file esisteva, esattamente com'è ora, in un certo
momento: una prova di esistenza e di integrità basata sulla marcatura temporale (trusted
timestamping). Tre autorità di marcatura temporale indipendenti (TSA, Time Stamping
Authority) firmano l'hash SHA-256 del file insieme alla propria data e ora (marche
temporali RFC 3161), e le prove si possono verificare in qualsiasi momento, con questo
script o a mano con `openssl`.

È un solo script Bash senza librerie aggiuntive: usa `openssl`, `curl` e gli strumenti
standard del sistema, e funziona su Linux, su Windows in WSL e su macOS. In rete viaggia
solo l'hash del file, mai il suo contenuto.

Prima volta? **[QUICKSTART.it.md](QUICKSTART.it.md)** mostra ogni passo con un esempio
reale.

> Lo script, i suoi messaggi e i commenti nel codice sono in inglese; questa è la
> traduzione italiana della documentazione. In caso di differenze fa fede il
> [README in inglese](README.md).

## Perché

Le date di un file (creazione, ultima modifica) le può cambiare chiunque e non provano
nulla. Una marca temporale firmata da un'autorità indipendente invece sì: lega l'hash del
file a una data che chi possiede il file non può alterare. Funziona con qualsiasi file
digitale: il codice sorgente o l'archivio di release di un programma, un eseguibile, un
dataset, immagini, video, musica, un manoscritto, un progetto grafico, un insieme di
documenti: tutto ciò di cui in futuro potresti dover dimostrare l'esistenza, in quella
forma esatta, a una certa data. Può servire, per esempio, a difendere il diritto
d'autore su un'opera: vedi [Valore legale](#valore-legale).

Lo script interpella tre autorità insieme, conserva ogni risposta con i certificati che
servono a verificarla e raccoglie tutto in una cartella che si spiega da sola, così la
prova si può verificare anche dopo anni, da chiunque, con strumenti standard.

---

## Indice

- [Come funziona](#come-funziona)
  - [Certificati radice](#certificati-radice)
- [Requisiti](#requisiti)
- [Installazione](#installazione)
  - [Windows (WSL)](#windows-wsl)
- [Utilizzo](#utilizzo)
- [Proteggere un'opera, passo per passo](#proteggere-unopera-passo-per-passo)
- [Configurazione](#configurazione)
- [La cartella delle prove](#la-cartella-delle-prove)
- [Copie, spostamenti e archivi](#copie-spostamenti-e-archivi)
- [Verifica](#verifica)
  - [Con lo script](#con-lo-script)
  - [A mano](#a-mano)
  - [Nel lungo periodo](#nel-lungo-periodo)
- [Controllo dello script](#controllo-dello-script)
- [Esempio di output](#esempio-di-output)
- [Valore legale](#valore-legale)
- [Servizi esterni contattati](#servizi-esterni-contattati)
- [Codici di uscita](#codici-di-uscita)
- [Struttura del progetto](#struttura-del-progetto)
- [Versioni](#versioni)
- [Licenza e disclaimer](#licenza-e-disclaimer)

---

## Come funziona

1. Lo script calcola l'hash SHA-256 del file e prepara una sola richiesta RFC 3161, che
   contiene soltanto quell'hash.
2. Invia la richiesta a tre autorità di marcatura temporale indipendenti:

   | TSA | Indirizzo | Note |
   |-----|-----------|------|
   | FreeTSA | `https://freetsa.org/tsr` | TSA pubblica gratuita |
   | DigiCert | `http://timestamp.digicert.com` | usata in tutto il mondo per la firma del codice |
   | Sectigo | `http://timestamp.sectigo.com` | usata in tutto il mondo per la firma del codice |

3. Ogni TSA restituisce una marca temporale firmata: l'hash, la data e l'ora della TSA e
   la sua firma. Una risposta viene conservata solo se la TSA ha **accettato** la
   richiesta.
4. Ogni marca viene controllata subito con i certificati della TSA. Il resoconto tiene
   distinte due cose: **ottenuta** (la TSA ha risposto e la risposta è stata salvata) e
   **verificata** (anche la firma è stata controllata qui, alla data firmata dalla TSA,
   quindi un orologio sbagliato sul tuo computer non conta). Solo le marche verificate
   contano come successo; una marca che non si è potuta verificare viene comunque
   conservata, e si può controllare più tardi.

Ogni marca vale da sola; più autorità indipendenti che confermano lo stesso hash rendono
la prova più solida, e la prova resiste anche se un'autorità scompare. Non servono
chiavi, account, firme o password.

DigiCert e Sectigo si contattano in HTTP semplice. Per RFC 3161 è normale: la risposta è
firmata digitalmente e viene controllata, quindi non si può alterare senza che ce ne si
accorga.

### Certificati radice

Una firma è affidabile quanto il certificato radice con cui viene controllata. Per questo
lo script controlla ogni marca solo con il certificato radice della **sua** TSA, e non
usa mai quelli che arrivano insieme alle prove: chi ha creato prove false potrebbe aver
creato anche quel certificato. Le tre radici sono conservate in
`ndm_file-timestamp-certs/` accanto allo script. Il repository non le contiene: ogni
utente scarica e controlla le proprie.

| TSA | Certificato radice | Da scaricare da | SHA-256 del file |
|-----|--------------------|-----------------|------------------|
| FreeTSA | FreeTSA Root CA (valido fino al 2041) | `https://freetsa.org/files/cacert.pem` | `2151b61137ffa86bf664691ba67e7da0b19f98c758e3d228d5d8ebf27e044438` |
| DigiCert | DigiCert Trusted Root G4 (2038) | `http://cacerts.digicert.com/DigiCertTrustedRootG4.crt` | `552f7bdcf1a7af9e6ce672017f4f12abf77240c78e761ac203d1d9d20ac89988` |
| Sectigo | USERTrust RSA Certification Authority (2038) | `http://crt.usertrust.com/USERTrustRSACertificationAuthority.crt` | `e793c9b02fd8aa13e21c31228accb08119643b749c898964b1746d46c3d4cbd2` |

Gli stessi valori sono scritti nello script, e puoi confrontarli con fonti indipendenti:
FreeTSA pubblica lo SHA-256 del suo file su [freetsa.org](https://freetsa.org). I file
`.crt` di DigiCert e Sectigo sono il certificato puro, quindi il loro SHA-256 è
l'impronta del certificato, la stessa dell'elenco CA di Mozilla (il pacchetto
`ca-certificates` del tuo sistema) e di [crt.sh](https://crt.sh/). Scaricarli in HTTP
semplice va bene: un file con uno SHA-256 diverso non viene mai conservato. Le marche di
Sectigo portano alla radice USERTrust (gestita anch'essa da Sectigo) perché la loro catena
di certificati passa da lì. La scadenza di una radice non conta per le marche già fatte:
vengono controllate alla loro data.

**Sono indispensabili.** Senza di esse nessuna marca si può controllare, e nulla
mostrerebbe che una data viene davvero da una TSA. Per questo, quando ne manca una, lo
script se ne occupa prima di tutto il resto (prima di contattare una TSA o di creare una
cartella): spiega il motivo, elenca quelle mancanti e, su un terminale, chiede conferma
prima di scaricarle. Per ognuna mostra lo SHA-256 atteso e quello ottenuto, e conserva
solo i file che corrispondono. Se rispondi no, o un download non riesce, lo script si
ferma e ricorda come procurarle. `--get-certs` fa lo stesso in qualsiasi momento e
mostra quali radici sono presenti.

**A mano.** Scarica i tre file in `ndm_file-timestamp-certs/` e controllali:

```bash
cd ndm_file-timestamp-certs
curl -O https://freetsa.org/files/cacert.pem
curl -O http://cacerts.digicert.com/DigiCertTrustedRootG4.crt
curl -O http://crt.usertrust.com/USERTrustRSACertificationAuthority.crt
sha256sum *        # macOS: shasum -a 256 *
```

Ogni SHA-256 deve essere quello della tabella e quello pubblicato dalla TSA: cancella i
file che non corrispondono. Se una TSA ha riformattato il suo file, con lo stesso
certificato dentro, lo script lo accetta comunque purché contenga solo quel certificato:
confronta allora l'impronta del certificato (`openssl x509 -in FILE -noout -fingerprint
-sha256`; FreeTSA: `a6379e7cecc05faa3cbf076013d745e327bbbaa38c0b9af22469d4701d18aabc`,
per le altre due è il valore della tabella). Lo script riconosce le radici dal contenuto, qualunque sia il
nome del file; `./ndm_file-timestamp.sh --get-certs` le mostra poi come `OK`.

**Controllarle in seguito.** `./ndm_file-timestamp.sh --verify-certs` controlla, senza
rete e senza modificare nulla, che ogni radice fidata ci sia byte per byte (il suo
SHA-256), e segnala ogni altro file nella cartella: `ALTERED` quando ha il nome di una
radice ma non il suo contenuto. Termina con codice 0 solo se è tutto in ordine. In un
archivio estratto controlla le radici dell'archivio.

**Nuove radici.** Un giorno una TSA comincerà a usare una radice nuova: vedi
[Nel lungo periodo](#nel-lungo-periodo).

## Requisiti

| Strumento | Serve per |
|-----------|-----------|
| `openssl` | Richieste RFC 3161, controllo delle firme |
| `curl` | Invio delle richieste alle TSA (non serve a `--verify`) |
| `sha256sum` (coreutils; su macOS `shasum`) | L'hash del file |
| Certificati CA di sistema (`ca-certificates`) | I download in HTTPS fatti da `curl` |

Sono tutti obbligatori. Su Linux lo script usa le GNU coreutils; su macOS usa gli
strumenti del sistema (Bash 3.2, `date` e `stat` BSD, `shasum`), quindi lì non serve
installare nulla (OpenSSL 3 è consigliato: vedi sotto). Lancia `./ndm_file-timestamp.sh --requirements` per vedere cosa manca e il comando esatto
per installarlo sul tuo sistema:

| Sistema | Comando |
|---------|---------|
| Debian / Ubuntu | `sudo apt install openssl curl coreutils ca-certificates` |
| Fedora / RHEL 8+ | `sudo dnf install openssl curl coreutils ca-certificates` |
| CentOS / RHEL 7 | `sudo yum install openssl curl coreutils ca-certificates` |
| openSUSE | `sudo zypper install openssl curl coreutils ca-certificates` |
| Arch / Manjaro | `sudo pacman -S openssl curl coreutils ca-certificates` |
| Alpine | `sudo apk add bash openssl curl coreutils ca-certificates` (prima bash: Alpine non lo include) |
| macOS | Niente: `openssl` (LibreSSL), `curl`, `shasum` e i certificati sono già nel sistema |
| Windows | Usalo in WSL: vedi [Windows (WSL)](#windows-wsl) |

**OpenSSL 3 è consigliato.** Con LibreSSL (l'`openssl` di macOS) o OpenSSL 1.1
(distribuzioni Linux meno recenti) ci sono dei limiti:

- **Le marche di Sectigo non si verificano.** Queste versioni controllano l'elenco dei
  certificati nella marca in modo più rigido di OpenSSL 3, e l'elenco di Sectigo non
  comprende la sua radice. Le marche vengono comunque ottenute e conservate, lo script
  spiega perché non sono verificate, e si verificano con OpenSSL 3. FreeTSA e DigiCert si
  verificano normalmente, quindi il file risulta comunque confermato (a meno che
  `MIN_TIMESTAMPS` non richieda tutte e tre le TSA).
- **Certificati scaduti (solo LibreSSL).** LibreSSL potrebbe non supportare `-attime` in
  `openssl ts -verify`. In quel caso `--verify` lo segnala e controlla i certificati alla
  data attuale: tutto funziona finché un certificato di una TSA non scade (quelli attuali
  scadono tra il 2037 e il 2040); dopo, quelle marche non si verificano più.

Su macOS, installa OpenSSL 3 con Homebrew e mettilo per primo nel `PATH` (aggiungi la
riga `export` a `~/.zprofile` per mantenerlo):

```bash
brew install openssl@3
export PATH="$(brew --prefix openssl@3)/bin:$PATH"
openssl version          # OpenSSL 3.x
```

## Installazione

```bash
git clone https://github.com/nidamanx/NDM_File-Timestamp.git
cd NDM_File-Timestamp
chmod +x ndm_file-timestamp.sh
./ndm_file-timestamp.sh --requirements      # controlla gli strumenti necessari
```

Facoltativo: rendilo disponibile ovunque con un collegamento simbolico. Lo script salva
comunque le prove accanto alla sua posizione reale.

```bash
ln -s "$PWD/ndm_file-timestamp.sh" ~/.local/bin/ndm_file-timestamp
```

### Windows (WSL)

Lo script richiede una shell Linux. Su Windows 10 e 11 va usato dentro **WSL** (Windows
Subsystem for Linux), che fornisce un vero ambiente Ubuntu. Git Bash, MSYS2 e Cygwin non
sono supportati.

1. Apri **PowerShell come amministratore**, installa WSL (Ubuntu di default) e riavvia
   Windows quando richiesto:

   ```powershell
   wsl --install
   ```

2. Apri **Ubuntu** dal menu Start, crea il tuo utente Linux quando richiesto, poi
   installa gli strumenti e lo script nella tua home Linux:

   ```bash
   sudo apt update
   sudo apt install git openssl curl coreutils ca-certificates
   cd ~
   git clone https://github.com/nidamanx/NDM_File-Timestamp.git
   cd NDM_File-Timestamp
   ./ndm_file-timestamp.sh --requirements
   ```

Note per Windows:

- Tieni lo script nella home Linux (`~`), non sotto `/mnt/c/...`: sui dischi di Windows
  il permesso di esecuzione può andare perso.
- I tuoi file di Windows sono raggiungibili da WSL sotto `/mnt/c/...`: indica allo script
  il loro percorso, per esempio `/mnt/c/Users/<tuo utente>/Documents/project.zip`. Le
  prove vengono salvate accanto allo script, nella home Linux.
- Clona da dentro WSL. Il `.gitattributes` del repository mantiene le fini riga Linux
  anche se cloni con Git for Windows: quelle di Windows (CRLF) romperebbero lo script con
  errori come `/usr/bin/env: 'bash\r': No such file or directory`.

### Aggiornamento

`--check-script` segnala quando è uscita una versione più recente. In un clone del
repository, sul ramo `main` e senza modifiche locali, propone anche di aggiornarlo subito
(si può fare lo stesso a mano):

```bash
cd NDM_File-Timestamp
git pull --ff-only
```

Se hai scaricato solo lo script, scarica quello nuovo dall'[ultima
release](https://github.com/nidamanx/NDM_File-Timestamp/releases/latest), sostituisci il
vecchio file, esegui `chmod +x ndm_file-timestamp.sh` e controllalo come in [Controllo
dello script](#controllo-dello-script). Se `git status` mostra modifiche locali, tienine
una copia ed eliminale (`git checkout -- ndm_file-timestamp.sh`) prima di aggiornare.

L'aggiornamento non tocca mai le tue prove, gli archivi, i certificati radice né le
impostazioni: non fanno parte del repository. Le versioni nuove continuano a verificare
le prove create da quelle precedenti.

## Utilizzo

```
./ndm_file-timestamp.sh [-d DIR] FILE...            crea le marche temporali
./ndm_file-timestamp.sh --verify [-d DIR] FILE...   verifica i file con le loro marche
./ndm_file-timestamp.sh --list [-d DIR]             elenca le prove salvate
./ndm_file-timestamp.sh --archive [-d DIR] FILE...  raccoglie ogni file con le prove e lo script
./ndm_file-timestamp.sh --archive [-d DIR] FILE --attach FILE|DIR...
                                                    lo stesso, con allegati
```

| Opzione | Descrizione |
|---------|-------------|
| `--verify FILE...` | Verifica ogni `FILE` con **tutte** le sue prove e mostra le date che certificano (UTC e ora locale), più la data più antica dimostrata. Non contatta nessuna TSA |
| `-l`, `--list` | Elenca le prove nella cartella delle prove (o in `DIR` con `-d`, o `OUTPUT_DIR`): file, data dell'esecuzione, numero di marche e inizio dell'hash. Le date delle esecuzioni vengono dall'orologio del tuo computer; quelle certificate le mostra `--verify` |
| `-a`, `--archive FILE...` | Verifica ogni `FILE`, poi lo raccoglie con le sue prove valide, i certificati radice, questo script e la sua licenza in un unico `.tar` nella cartella degli archivi accanto allo script (vedi [Copie, spostamenti e archivi](#copie-spostamenti-e-archivi)) |
| `--attach FILE\|DIR` | Con `--archive` e un solo `FILE`: mette anche questo file, o ogni file direttamente dentro `DIR`, in `attachments/` dell'archivio, con le loro prove valide (per esempio una dichiarazione di paternità firmata, le ricevute PEC). Ripetibile. Un allegato senza marche valide viene incluso lo stesso, con un avviso |
| `-d`, `--output-dir DIR` | Salva le prove in `DIR` invece che nella cartella accanto allo script, per esempio su un disco di backup. `DIR` viene creata se manca; un `DIR` relativo parte dalla cartella corrente. Con `--verify`, le prove vengono cercate anche in `DIR` |
| `--` | Fine delle opzioni: quello che segue sono file, anche se il nome comincia con `-` |
| `--check-script` | Confronta questo script con quello pubblicato su GitHub per la sua versione (vedi [Controllo dello script](#controllo-dello-script)) |
| `--get-certs` | Mostra i certificati radice delle TSA e scarica quelli mancanti, mostrando ogni controllo (vedi [Certificati radice](#certificati-radice)) |
| `--verify-certs` | Controlla, senza rete, che ogni certificato radice ci sia e non sia alterato, e che nella loro cartella non ci sia altro |
| `--requirements` | Mostra gli strumenti necessari e come installarli |
| `-v`, `--version` | Mostra nome, versione, autore, licenza e disclaimer |
| `-h`, `--help` | Mostra l'aiuto |

Esempi:

```bash
# Crea le prove di un file
~/NDM_File-Timestamp/ndm_file-timestamp.sh ~/Documents/project.zip

# Più file insieme
~/NDM_File-Timestamp/ndm_file-timestamp.sh contratto.pdf disegni.zip note.odt

# Prove salvate su un disco di backup invece che accanto allo script
~/NDM_File-Timestamp/ndm_file-timestamp.sh -d /media/backup/prove project.zip

# Più tardi: verifica il file con le sue prove
~/NDM_File-Timestamp/ndm_file-timestamp.sh --verify ~/Documents/project.zip

# Quali prove ci sono?
~/NDM_File-Timestamp/ndm_file-timestamp.sh --list

# Il file, le sue prove e lo script in un unico archivio, da conservare o spostare
~/NDM_File-Timestamp/ndm_file-timestamp.sh --archive ~/Documents/project.zip

# Lo stesso, con la dichiarazione firmata e le ricevute che accompagnano il file
~/NDM_File-Timestamp/ndm_file-timestamp.sh --archive ~/Documents/project.zip \
    --attach ~/Documents/dichiarazione.pdf --attach ~/Documents/ricevute/
```

Con più file, ognuno ha la sua cartella di prove e il suo resoconto, e un riepilogo finale
mostra l'esito di ogni file. Tutti i file devono esistere prima che venga inviato
qualcosa. Ogni esecuzione crea nuove cartelle di prove, quindi puoi marcare di nuovo lo
stesso file in seguito: `--verify` elenca allora ogni insieme di prove e la data più
antica.
Un file il cui nome comincia con `-` va indicato dopo `--`, oppure con un percorso come
`./-note.txt`.

I file da marcare possono stare ovunque. Se vuoi, tienili in `ndm_file-timestamp-files/`
accanto allo script, e i documenti che li accompagnano ([modelli](templates/) compilati,
ricevute) in `ndm_file-timestamp-attachments/`: come la cartella delle prove, fanno
parte del repository, vuote tranne un file `.gitkeep`, e Git ne ignora il contenuto,
così i tuoi file restano separati dal programma e non finiscono mai in un commit per
sbaglio. Lo script non le consulta da solo: indica il percorso, per esempio
`./ndm_file-timestamp.sh ndm_file-timestamp-files/project.zip`.

I colori vengono usati solo quando l'output va su un terminale; imposta `COLORS=off` nel
file di configurazione, oppure `NO_COLOR=1`, per toglierli anche lì. L'output salvato su
file o passato a una pipe è testo semplice.

## Proteggere un'opera, passo per passo

**[QUICKSTART.it.md](QUICKSTART.it.md)** segue tutta la procedura con un esempio reale,
dall'installazione all'archivio conservato in due posti. In breve:

1. Marca l'opera (e ogni versione importante, anche le bozze).
2. Verificala e annota lo SHA-256 e la data "at least since".
3. Compila la [dichiarazione di paternità](templates/) e firmala.
4. Marca la dichiarazione firmata.
5. Facoltativo: PEC, marca qualificata o registrazione presso l'ente del tuo paese.
6. Raccogli tutto con `--archive FILE --attach CARTELLA`.
7. Conserva l'archivio in due posti e controlla ogni copia con `--verify`.

Per quanto valgono queste prove, vedi [Valore legale](#valore-legale).

## Configurazione

I valori predefiniti funzionano senza nessuna configurazione. Per cambiarli senza scrivere
opzioni a ogni esecuzione, crea un file di configurazione accanto allo script, partendo dal
modello:

```bash
cp ndm_file-timestamp.conf.example ndm_file-timestamp.conf
```

| Impostazione | Predefinito | Significato |
|--------------|-------------|-------------|
| `OUTPUT_DIR` | la cartella delle prove accanto allo script | Cartella delle prove: relativa alla cartella dello script, o assoluta. `-d` vince su questa impostazione. Le prove già salvate accanto allo script vengono comunque trovate da `--verify` |
| `ARCHIVE_DIR` | la cartella degli archivi accanto allo script | Cartella in cui `--archive` crea gli archivi: relativa alla cartella dello script, o assoluta |
| `TSAS` | `freetsa digicert sectigo` | Le TSA da interpellare, separate da spazi o virgole |
| `MIN_TIMESTAMPS` | `1` | Quante TSA diverse devono confermare un file, sia nella creazione sia nella verifica. Un valore più alto dà una prova più solida, ma basta allora una TSA fuori servizio per fallire |
| `SCRIPT_CHECK` | `off` | `on`: confronta lo script con quello pubblicato prima di ogni esecuzione (vedi [Controllo dello script](#controllo-dello-script)) |
| `COLORS` | `on` | `off`: niente colori |

- Un `CHIAVE=valore` per riga; le righe che cominciano con `#` vengono ignorate; le
  virgolette sono facoltative.
- Il file viene solo letto, mai eseguito: i comandi scritti al suo interno non partono.
- È personale ed escluso da Git; è versionato solo il modello `.example`.
- Un'impostazione nell'ambiente vince sul file, e la riga di comando vince su entrambi.
- Un valore non valido ferma lo script con codice di uscita 2 e indica l'impostazione
  sbagliata.

## La cartella delle prove

Le prove vengono salvate in `ndm_file-timestamp-proofs/` **accanto allo script** (nella
sua posizione reale, anche quando viene avviato da un collegamento simbolico), con una
sottocartella per ogni esecuzione (data e ora UTC), così le prove precedenti non vengono
mai sovrascritte.

La cartella fa parte del repository, vuota tranne un file `.gitkeep`, così si vede fin
dall'inizio dove finiranno le prove. Git ignora tutto il resto del suo contenuto, quindi le
tue prove non finiscono mai in un commit e `git pull` non le tocca. Se la cartella viene
cancellata, lo script la ricrea alla prossima esecuzione. Con `-d DIR` le prove vanno
invece in `DIR`, con la stessa struttura.

```
NDM_File-Timestamp/
└── ndm_file-timestamp-proofs/
    ├── .gitkeep                       mantiene la cartella vuota nel repository
    ├── project.zip_20261026-062932.log  resoconto dell'esecuzione, come a video
    └── project.zip_20261026-062932/
        ├── README.txt                 cosa contiene ogni file e come verificare a mano
        ├── file-info.txt              SHA-256, dimensione, date, script che ha creato le prove
        ├── project.zip.sha256         checksum SHA-256, utilizzabile con "sha256sum -c"
        ├── project.zip.tsq            richiesta RFC 3161 inviata alle TSA (solo l'hash)
        ├── project.zip.freetsa.tsr    risposta RFC 3161 = LA MARCA TEMPORALE (da conservare!)
        ├── project.zip.freetsa.txt    marca leggibile: cerca la riga "Time stamp"
        ├── freetsa-certs.pem          certificati necessari per verificare il .tsr
        ├── freetsa-2151b61137ffa86b.pem  copia della radice di FreeTSA, per i passi a mano
        ├── freetsa-verify.txt         esito della verifica fatta subito
        └── …                          gli stessi file per digicert e sectigo
                                       (i loro certificati radice arrivano con ca-certificates)
```

Da tenere presente:

- **Conta solo il contenuto del file.** Cambiare un solo byte invalida tutte le prove;
  nome, cartella, date e permessi non contano (vedi
  [Copie, spostamenti e archivi](#copie-spostamenti-e-archivi)).
- **Il file originale non viene copiato**: le prove restano accanto allo script, il file
  resta dov'è. Conserva copie di entrambi, in almeno due posti: `--archive` li raccoglie
  insieme.
- **Le prove stanno dentro la tua copia del repository.** Salva la cartella delle prove
  prima di cancellare o spostare quella copia, e includila nei tuoi backup.
- **La cartella è personale**: contiene in chiaro nome, dimensione, date e hash del file.
- La riga "Proofs created" di `file-info.txt` è l'orologio del tuo computer, non una
  prova: contano le date firmate dalle TSA.

## Copie, spostamenti e archivi

Una marca temporale copre il **contenuto** del file, byte per byte, e nient'altro.
Spostare il file, rinominarlo, copiarlo su un altro disco o computer, cambiarne date o
permessi: nulla di tutto questo tocca le prove. `--verify` riconosce un file dal suo
contenuto, quindi verifica anche una copia rinominata, indicando il nome che aveva quando
è stato marcato.

Le prove non corrispondono più quando cambia il **contenuto**, anche senza che te ne
accorga:

- uno zip o un altro archivio viene ricreato, anche partendo dagli stessi file;
- vengono convertite le fini riga (FTP in modalità testo, alcuni programmi di posta,
  editor che "sistemano" il file);
- un servizio cloud converte il file nel proprio formato, o ricomprime immagini e PDF;
- il file viene aperto e salvato di nuovo (i programmi da ufficio lo fanno anche senza
  modifiche);
- una copia si interrompe o il disco si danneggia.

Un file il cui contenuto è cambiato non si può riparare: si può verificare solo una copia
invariata. Quindi, dopo aver copiato il file altrove, lancia `--verify` **sulla copia**
prima di cancellare l'originale.

Per conservare o spostare tutto insieme, usa `--archive`:

```bash
./ndm_file-timestamp.sh --archive project.zip
```

Prima verifica il file: l'archivio nasce solo se almeno una marca è valida. Crea
`project.zip_bundle_<AAAAMMGG>-<HHMMSS>.tar` in `ndm_file-timestamp-archives/` accanto
allo script (o in `ARCHIVE_DIR`) e, accanto a esso,
`project.zip_bundle_<AAAAMMGG>-<HHMMSS>.log`, il resoconto di quell'esecuzione come appare
a schermo (senza colori): quali prove e quali allegati erano validi quando l'archivio è
stato creato. Come la cartella delle prove, anche questa fa parte del repository, vuota
tranne un file `.gitkeep`: Git ignora gli archivi, e lo script ricrea la cartella se
manca. L'archivio contiene:

```
project.zip_bundle_20261026-065616/
├── project.zip                  il file, byte per byte quello marcato
├── ndm_file-timestamp-proofs/   le sue cartelle di prove con una marca valida, e i loro log
├── attachments/                 solo con --attach: i documenti che accompagnano il file
├── ndm_file-timestamp-certs/    le tre radici delle TSA, così l'archivio si verifica senza rete
├── ndm_file-timestamp.sh        questo script, che ha creato le prove e le verifica
├── LICENSE                      la sua licenza (GNU AGPL v3)
├── SHA256SUMS                   SHA-256 del file (e degli allegati) e dello script
└── README.txt                   cosa contiene l'archivio e come verificarlo
```

I documenti che accompagnano il file, come la
[dichiarazione di paternità](templates/) firmata o le ricevute di una PEC, possono stare
nello stesso archivio con `--attach` (un solo `FILE` per archivio, così è chiaro a quale
opera appartengono):

```bash
./ndm_file-timestamp.sh --archive project.zip \
    --attach ndm_file-timestamp-attachments/project/
```

`--attach` accetta un file o una cartella (i file direttamente al suo interno), e si può
ripetere. Ogni allegato viene verificato come il file: anche le sue prove valide entrano
nell'archivio, così `./ndm_file-timestamp.sh --verify attachments/dichiarazione.pdf`
funziona nella cartella estratta. Marca la dichiarazione **prima** di archiviarla: un
allegato senza marche valide (per esempio una ricevuta PEC, che ha un valore proprio)
viene incluso lo stesso, con un avviso, e il `README.txt` dell'archivio dice quali
allegati sono confermati dalle marche. Mettere un file nell'archivio non gli dà una data:
gliela danno solo le sue marche.

L'archivio è completo: anche dopo anni, su un altro computer, lo estrai e lanci
`./ndm_file-timestamp.sh --verify project.zip` dentro la cartella estratta. Le prove si
possono verificare anche a mano con `openssl`, senza lo script. Lo SHA-256 dello script in
`SHA256SUMS` si può confrontare con la stessa versione pubblicata in questo repository.

## Verifica

### Con lo script

```bash
./ndm_file-timestamp.sh --verify project.zip
```

`--verify` cerca le prove nella cartella accanto allo script, in `DIR` se indicata con
`-d`, e in una cartella `ndm_file-timestamp-proofs/` nella cartella corrente o accanto al
file (per prove che hai spostato lì, per esempio insieme al file). Per ogni insieme di
prove confronta l'hash attuale del file con quello salvato (un file modificato viene segnalato come **MODIFIED**), controlla ogni marca e
chiude con la data più antica dimostrata. Funziona senza rete, tranne la prima volta che
servono i certificati radice (vedi [Certificati radice](#certificati-radice)).

I certificati vengono controllati **alla data di ogni marca**. I certificati delle TSA
scadono (quelli attuali tra il 2037 e il 2040): una marca firmata mentre il suo
certificato era valido resta valida anche dopo, quindi le prove vecchie continuano a
verificarsi.

### A mano

Le prove non dipendono da questo script: chiunque può controllarle con `openssl` (il
`README.txt` di ogni cartella di prove ripete questi passi):

```bash
P=~/NDM_File-Timestamp/ndm_file-timestamp-proofs/project.zip_20261026-062932
F=~/Documents/project.zip

# 1. Il file è invariato: dalla cartella che lo contiene
cd "$(dirname "$F")" && sha256sum -c "$P/project.zip.sha256"

# 2-5: da dentro la cartella delle prove
cd "$P"

# 2. I certificati radice sono quelli veri: ogni SHA-256 deve essere quello di
#    "Certificati radice" qui sopra e quello pubblicato dalla TSA
sha256sum freetsa-*.pem digicert-*.crt sectigo-*.crt

# 3. La marca è valida (FreeTSA)
openssl ts -verify -data "$F" -in project.zip.freetsa.tsr \
    -CAfile freetsa-2151b61137ffa86b.pem -untrusted freetsa-certs.pem

# 4. La marca è valida (DigiCert; Sectigo allo stesso modo, con il suo .crt):
#    la radice .crt va prima convertita in PEM
openssl x509 -inform DER -in digicert-552f7bdcf1a7af9e.crt -out /tmp/digicert-root.pem
openssl ts -verify -data "$F" -in project.zip.digicert.tsr \
    -CAfile /tmp/digicert-root.pem -untrusted digicert-certs.pem

# 5. La data certificata
openssl ts -reply -in project.zip.freetsa.tsr -text | grep 'Time stamp'
```

Il passo 2 è importante: non fidarti mai di un certificato radice solo perché si trova
accanto alle prove.

I comandi `openssl` si lanciano da dentro la cartella delle prove perché openssl spezza
agli spazi il percorso di `-untrusted`, e la cartella porta il nome del file: un nome con
spazi renderebbe il comando non valido.

Ogni controllo deve terminare con `Verification: OK`. openssl può anche avvisare che il
certificato della TSA "is not a CA cert": è previsto e non cambia l'esito.
Se un certificato della TSA è scaduto, aggiungi `-attime <epoch>` con la data della
marca, per esempio `-attime $(date -d "Oct 26 06:29:33 2026 GMT" +%s)`.
Su macOS usa `shasum -a 256 -c` al posto di `sha256sum -c`, e
`date -j -u -f '%b %d %H:%M:%S %Y %Z' "Oct 26 06:29:33 2026 GMT" +%s` per l'epoch.

### Nel lungo periodo

- **I certificati scaduti non contano.** `--verify` controlla ogni certificato alla data
  della marca, non a oggi: una marca firmata quando i suoi certificati erano validi resta
  valida anche dopo la loro scadenza (i certificati delle TSA scadono fra il 2037 e il
  2041). L'unica eccezione è l'`openssl` di macOS (LibreSSL), che potrebbe non supportarlo:
  lo script lo segnala, e OpenSSL 3 non ha questo limite (vedi "Requisiti").
- **Nuove radici.** Prima che una radice scada, la sua TSA passa a una nuova. Da due anni
  prima della scadenza lo stamp mostra un avviso; quando la TSA è passata alla nuova
  radice, le marche nuove vengono comunque salvate ma segnalate come collegate a nessuna
  radice fidata, finché una versione più recente dello script non aggiunge la nuova
  radice. Le marche già fatte continuano a verificarsi, anche con lo script archiviato.
- **Algoritmi più forti.** Fra molti anni RSA o SHA-256 potrebbero indebolirsi. Il rimedio
  abituale è marcare di nuovo l'archivio stesso ogni qualche anno (per esempio ogni cinque,
  o quando lo script annuncia una nuova radice): la nuova marca, fatta con gli algoritmi
  del suo tempo, copre l'archivio e le prove più vecchie che contiene.

  ```bash
  ./ndm_file-timestamp.sh ndm_file-timestamp-archives/project.zip_bundle_20261026-065616.tar
  ```

  Poi archivia anche quel `.tar` (`--archive` su di esso), o conservalo con le sue nuove
  prove.
- **Conserva gli archivi.** Ognuno contiene lo script del suo tempo, con le sue radici
  fidate, quindi si verifica da solo; controlla quello script con la verifica
  indipendente descritta in [Controllo dello script](#controllo-dello-script).

## Controllo dello script

È lo script a decidere se una prova è valida, quindi conta che sia esattamente quello
pubblicato. I controlli sono due.

**Controllo indipendente (quello che conta).** Non si affida allo script da controllare:
confronta lo SHA-256 della tua copia con il file pubblicato per la sua versione (sostituisci
`X.Y.Z` con la versione mostrata da `--version`):

```bash
sha256sum ndm_file-timestamp.sh
curl -fsSL https://raw.githubusercontent.com/nidamanx/NDM_File-Timestamp/vX.Y.Z/ndm_file-timestamp.sh | sha256sum
```

I due hash devono essere uguali (su macOS usa `shasum -a 256`). In un clone del
repository, anche `git status` e `git diff vX.Y.Z -- ndm_file-timestamp.sh` mostrano
qualsiasi modifica locale.

**Controllo integrato.** `--check-script` fa da solo lo stesso confronto, e
`SCRIPT_CHECK=on` nel file di configurazione lo esegue prima di ogni marcatura, verifica o
archivio: lo script si ferma se è diverso, e avvisa soltanto quando il confronto non è
possibile (senza rete, o con una versione non pubblicata). Tieni presente che uno script
non può garantire per se stesso: chi lo modifica di proposito può modificare anche questo
controllo. Serve contro copie danneggiate e modifiche maldestre; contro una manomissione
voluta conta solo il controllo indipendente.

Dopo il confronto, `--check-script` (e `SCRIPT_CHECK=on`) dice anche se è uscita una
versione più recente, con il link e come aggiornare (vedi [Aggiornamento](#aggiornamento)).
In un clone git senza modifiche, il solo `--check-script` propone anche di aggiornarlo:
chiede sempre prima, senza un terminale non aggiorna mai, e con `SCRIPT_CHECK=on` mostra
solo l'avviso, così una marcatura non viene mai interrotta. È solo un'informazione: non
cambia mai il codice di uscita né ferma l'esecuzione, e quando GitHub non risponde dice
che non può saperlo. Come per il confronto, uno script modificato può nascondere anche
questo avviso.

Ogni cartella di prove registra in `file-info.txt` lo SHA-256 dello script che l'ha
creata, e ogni archivio creato con `--archive` contiene lo script con il suo SHA-256 in
`SHA256SUMS`.

## Esempio di output

> **Nota:** questo output è solo un'illustrazione, ottenuta con un file di prova. Hash,
> date e percorsi cambiano a ogni esecuzione, e l'impaginazione può cambiare tra una
> versione e l'altra.

Creazione delle prove:

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

Verifica:

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

## Valore legale

Queste marche sono **prove tecniche**: mostrano, con crittografia standard, che un file
con quell'hash esatto esisteva non più tardi della data certificata. Il peso che hanno lo
decide chi le valuta, per esempio un giudice.

**A cosa servono.** Nella maggior parte dei paesi (quelli che aderiscono alla Convenzione
di Berna) il diritto d'autore nasce con la creazione dell'opera, senza registrazione: va
però dimostrato. Se qualcuno copia un tuo testo, programma, libro, immagine, video o
progetto e lo presenta come proprio, una marca anteriore alla sua pubblicazione è una
prova forte che l'opera esisteva già, in quella forma esatta, in una data precedente.
È una tutela gratuita, immediata e ripetibile a ogni versione dell'opera: non ha il peso
di una registrazione ufficiale, ma è molto meglio di nessuna prova, perché senza una
prova datata resta solo la tua parola contro quella di chi copia.

**Cosa non dimostrano.**

- **Chi** ha creato il file: la marca contiene solo l'hash, nessun nome, e chiunque abbia
  una copia può marcarla. La paternità si dimostra con altri mezzi, che la marca rafforza:
  file di lavoro originali, bozze precedenti (marca anche quelle, man mano che l'opera
  cresce), copie pubbliche (per esempio Internet Archive), una dichiarazione firmata
  (modello in [templates/](templates/), in italiano e in inglese; vedi
  [Proteggere un'opera, passo per passo](#proteggere-unopera-passo-per-passo)).
- La data di **creazione**: solo che il file esisteva entro quella data.
- Un file **diverso** da quello marcato, anche di poco (vedi
  [Copie, spostamenti e archivi](#copie-spostamenti-e-archivi)): conserva l'originale.
- Non danno diritti che la legge non dia già: non proteggono le idee e non sostituiscono
  un brevetto o un marchio.

**Quando serve una tutela più forte.** Nessuna delle tre TSA è un prestatore di servizi
fiduciari **qualificato** secondo il regolamento europeo eIDAS: le loro marche sono
ammesse come prova, ma non hanno la presunzione legale di esattezza della data delle
marche qualificate e in Italia non danno *data certa* in senso giuridico stretto. Per le
opere di valore importante usa lo script **insieme** a uno strumento con pieno valore
legale nel tuo paese, per esempio:

- una marca temporale **qualificata** (UE) da un prestatore elencato nelle liste di
  fiducia europee;
- in Italia, una **PEC** con il file allegato (anche a te stesso): conserva il messaggio
  e le ricevute (modello del testo in [templates/](templates/));
- il deposito o la registrazione presso l'ente del tuo paese (in Italia la **SIAE**, per
  le opere inedite; negli Stati Uniti lo U.S. Copyright Office; altrove l'ufficio
  nazionale del diritto d'autore);
- un atto notarile o un deposito presso un notaio.

Queste informazioni sono generali e non sono una consulenza legale: in caso di
controversia rivolgiti a un legale.

## Servizi esterni contattati

| Servizio | Serve per | Cosa riceve |
|----------|-----------|-------------|
| FreeTSA (`freetsa.org`, HTTPS) | Marca temporale; una sola volta, download del certificato radice | L'hash SHA-256 (nulla per il certificato) |
| DigiCert (`timestamp.digicert.com`, HTTP) | Marca temporale | L'hash SHA-256 |
| Sectigo (`timestamp.sectigo.com`, HTTP) | Marca temporale | L'hash SHA-256 |
| DigiCert (`cacerts.digicert.com`) e Sectigo (`crt.usertrust.com`), HTTP | Una sola volta, download dei certificati radice | Nulla |
| GitHub (`raw.githubusercontent.com`, HTTPS) | Solo `--check-script` e `SCRIPT_CHECK=on`: download dello script pubblicato | Nulla sui tuoi file |
| GitHub (`github.com`, HTTPS) | Solo `--check-script` e `SCRIPT_CHECK=on`: numero dell'ultima versione (`/releases/latest`) | Nulla sui tuoi file |

Non viene inviato nient'altro: né il file né il suo nome. Come per qualsiasi richiesta
web, i servizi vedono l'indirizzo IP del tuo computer. `--verify`, `--list`, `--archive`,
`--requirements`, `--version` e `--help` non contattano nessun servizio (salvo con
`SCRIPT_CHECK=on`), tranne l'unico download dei certificati radice quando non ci sono
ancora (anche con `--verify`, `--archive` e `--get-certs`). Ogni download è limitato a
30 secondi e 1 MB.

## Codici di uscita

| Codice | Significato |
|:------:|-------------|
| `0` | Ogni file ha ottenuto almeno una marca verificata (`MIN_TIMESTAMPS`), oppure `--verify` ha trovato almeno una marca valida per il contenuto attuale di ogni file, oppure `--archive` ha archiviato ogni file; `--list` sempre; `--verify-certs`: tutti i certificati radice ci sono e non sono alterati |
| `1` | Un file ha ottenuto meno marche verificate di `MIN_TIMESTAMPS` (per esempio senza rete) oppure, con `--verify`, non ha nessuna marca valida per il suo contenuto attuale (per esempio perché è stato modificato); con `--archive`, un file senza marche valide (l'archivio non viene creato); un file o un allegato non trovato o non leggibile, uno strumento mancante, o certificati radice mancanti (download rifiutato o non riuscito; `--get-certs`, `--verify-certs`) |
| `2` | Uso non valido della riga di comando (opzione sconosciuta, argomento mancante o di troppo), oppure un'impostazione non valida nel file di configurazione o nell'ambiente |

Così lo script si può usare da altri script.

## Struttura del progetto

```
NDM_File-Timestamp/
├── ndm_file-timestamp.sh          lo script
├── ndm_file-timestamp-files/      posto suggerito per i tuoi file da marcare (ignorati da Git)
│   └── .gitkeep                   mantiene la cartella vuota nel repository
├── ndm_file-timestamp-attachments/  le loro dichiarazioni e ricevute (ignorate da Git)
│   └── .gitkeep                   mantiene la cartella vuota nel repository
├── ndm_file-timestamp-certs/      certificati radice delle TSA, scaricati e controllati una volta (ignorati da Git)
│   └── .gitkeep                   mantiene la cartella vuota nel repository
├── ndm_file-timestamp-proofs/     le tue prove (contenuto ignorato da Git)
│   └── .gitkeep                   mantiene la cartella vuota nel repository
├── ndm_file-timestamp-archives/   i tuoi archivi creati con --archive, e i loro log (ignorati da Git)
│   └── .gitkeep                   mantiene la cartella vuota nel repository
├── templates/                     modelli vuoti da compilare (vedi la sezione passo per passo)
│   ├── authorship-declaration.en.txt  dichiarazione di paternità di un'opera, in inglese
│   ├── authorship-declaration.it.txt  la stessa in italiano
│   └── pec-message.it.txt         testo di un messaggio PEC (Italia)
├── ndm_file-timestamp.conf.example  modello di configurazione (versionato)
├── ndm_file-timestamp.conf        la tua configurazione (personale, ignorata da Git)
├── .github/workflows/ci.yml       controlli automatici (ShellCheck, versione, test su Linux e macOS)
├── .github/dependabot.yml         aggiornamenti mensili delle GitHub Actions usate dalla CI
├── .gitattributes                 mantiene le fini riga Linux (necessario su Windows)
├── .gitignore                     tiene fuori da Git i tuoi file, allegati, prove e archivi
├── LICENSE                        GNU AGPL v3
├── CHANGELOG.md                   modifiche di ogni versione
├── CITATION.cff                   come citare questo software (usato da GitHub)
├── SECURITY.md                    come segnalare una vulnerabilità
├── README.md                      documentazione in inglese
├── README.it.md                   documentazione in italiano
├── QUICKSTART.md                  guida passo passo con un esempio, in inglese
└── QUICKSTART.it.md               la stessa in italiano
```

## Versioni

Il progetto segue il [Semantic Versioning](https://semver.org/lang/it/). Nome,
descrizione, autore, versione e data di rilascio sono nel blocco **APP INFO** in cima a
`ndm_file-timestamp.sh`; `--version` li mostra. Ogni release ha un tag Git `vX.Y.Z`, e le
modifiche di ogni versione sono elencate in [CHANGELOG.md](CHANGELOG.md) (in inglese).

## Licenza e disclaimer

Copyright (C) 2023-2026 Nicola Davide Mannarelli ([@nidamanx](https://github.com/nidamanx))

Questo programma è software libero: puoi ridistribuirlo e/o modificarlo secondo i
termini della **GNU Affero General Public License** pubblicata dalla Free Software
Foundation, nella versione 3 della licenza o (a tua scelta) in qualsiasi versione
successiva (`SPDX-License-Identifier: AGPL-3.0-or-later`). Vedi il file
[LICENSE](LICENSE): il testo della licenza che ha valore legale è quello inglese.

**Citazione.** Se usi questo strumento, o parti del suo codice, nel tuo lavoro o in un
altro progetto, ti chiedo di citare *NDM File Timestamp* di Nicola Davide Mannarelli con
un link a questo repository. Il pulsante **Cite this repository** di GitHub, generato da
[CITATION.cff](CITATION.cff), fornisce una citazione pronta. La licenza richiede già che
le copie ridistribuite o modificate mantengano l'avviso di copyright.

**Disclaimer.** Questo software è fornito "così com'è", senza garanzie di alcun tipo,
esplicite o implicite. In nessun caso l'autore potrà essere ritenuto responsabile di
reclami, danni o altre responsabilità, compresi perdita di dati, marche temporali non
ottenute, prove non verificabili o non accettate come evidenza, derivanti dall'uso o
dall'uso improprio di questo software. Sei l'unico responsabile di come lo usi, della
conservazione dei tuoi file e delle loro prove, e di ogni decisione presa sulla base dei
suoi risultati. Questa è una traduzione di cortesia: fa fede il testo inglese.
