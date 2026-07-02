# Elektronska kockica

Projektni zadatak namenskog hardverskog sistema na **PYNQ-Z2** razvojnoj ploči. Sistem koristi linearni šift registar sa povratnom spregom (**LFSR**) za generisanje pseudo-nasumičnih brojeva visoke učestanosti i vrši digitalnu komparaciju sa unetim korisničkim brojem u realnom vremenu. Projekat implementira SoC (System-on-Chip) arhitekturu gde se hardverska logika (PL - Programmable Logic) povezuje sa ARM procesorom (PS - Processing System) preko **AXI magistrale** radi vođenja statistike i prikaza rezultata.

---

## 🎲 Kako igra radi?

1. **Podešavanje broja:** Korisnik pritiskom na fizičke tastere `btn[2:0]` podešava trobitni broj u opsegu od 0 do 7. Tasteri rade u *toggle* režimu (svaki pritisak invertuje vrednost odgovarajućeg bita), a trenutni izbor se odmah vizuelno mapira na diodama `led[2:0]`.


2. **Generisanje (Bacanje):** Pritiskom i držanjem tastera `btn[3]` pokreće se proces generisanja brojeva. Dokle god je taster pritisnut, interni generator menja stanja brzinom sistemskog takta ($125\text{ MHz}$), a diode brzo naizmenično blinkaju signalizirajući da je igra u toku.


3. **Poređenje:** Otpuštanjem tastera `btn[3]`, vrednost generatora se trenutno "zamrzava" i uzimaju se njegova poslednja 3 bita. Hardverski komparator upoređuje izvučeni broj sa brojem koji je korisnik prethodno podesio.


4. **Ishod i Reset:**
* **Pogodak:** Sve 4 LED diode sinhronizovano blinkaju brzo.


* **Promašaj:** Diode blinkaju u alternativnom ritmu.


* Nakon isteka reset tajmera (oko 2 sekunde), igra se automatski vraća u početno stanje sa nuliranim parametrima.




5. **ARM statistika:** Logika igre u svakom trenutku ažurira izlazne registre prema AXI interfejsu. ARM procesor sa PS strane preuzima ove vrednosti i vodi evidenciju o ukupnom broju pokušaja, broju pogodaka i procentu uspešnosti, prikazujući podatke u realnom vremenu na terminalu ili kroz prateći program.



---

## 🛠️ Hardverska arhitektura i moduli

Projekat je strukturisan modularno kroz čist, sintabilan Verilog HDL i sastoji se od četiri ključne komponente koje povezuje `top_module.v`:

```
                  +----------------------------------------------+
                  |                  top_module                  |
                  +----------------------------------------------+
                         |        |        |        |
    [btn[2:0]] ----------+        |        |        +---------- [led[3:0]]
    [btn[3]] ------------+        |        |        +---------- [AXI interfejs]
                                  v        v
         +--------------------------------------------------+
         | 4x debounce_filter                               |
         | (Uklanjanje šuma i vibracija mehaničkih tastera) |
         +--------------------------------------------------+
                                  |
                                  v
         +--------------------------------------------------+
         | lfsr_generator                                   |
         | (8-bitni pseudo-random generator na 125 MHz)     |
         +--------------------------------------------------+
                                  |
                                  v
         +--------------------------------------------------+
         | pynq_game_logic                                  |
         | (FSM igre, komparator, LED efekti i AXI registri)|
         +--------------------------------------------------+

```

### 1. Antivibracioni filter (`debounce_filter.v`)

Pošto mehanički kontakti tastera vibriraju pri pritisku, ovaj modul filtrira šum kako logika ne bi registrovala lažna uzastopna okidanja. Sadrži interni 22-bitni brojač. Tek kada signal sa tastera zadrži stabilno stanje neprekidno $2.500.000$ taktnih ciklusa (što na frekvenciji od $125\text{ MHz}$ iznosi tačno $20\text{ ms}$), stabilna logička vrednost se propušta dalje u sistem.

### 2. Pseudo-random generator (`lfsr_generator.v`)

Implementira 8-bitni *Linear-Feedback Shift Register*. Povratna sprega (feedback) je realizovana preko **XNOR** logičke kapije nad bitovima na pozicijama `0`, `2`, `3` i `4` (*taps*). Ovakva konfiguracija obezbeđuje maksimalnu dužinu sekvence (255 stanja pre ponavljanja) i generiše pseudo-nasumične podatke pri svakom taktu od $125\text{ MHz}$ dokle god je taster aktivan.

### 3. Logika igre i komparator (`pynq_game_logic.v`)

Centralni modul koji koordinira rad celog sistema.

* **Upravljanje unosom:** Kada igra nije pokrenuta, pritisak na stabilne tastere `btn_user` menja vrednost internog 3-bitnog registra `user_num`.


* **Semplovanje:** Kada se `btn_roll` spusti na nulu (otpuštanje tastera), blokira se dalji rad LFSR-a i donja tri bita registra `lfsr_rand[2:0]` se upisuju u registar `rolled_num`.


* **Komparacija i vizuelizacija:** Kombinacionom logikom se poredi `user_num == rolled_num`. Modul sadrži delitelj takta (`clk_div`) pomoću kojeg kontroliše frekvenciju blinkanja dioda zavisno od stanja (brzo šetanje svetla tokom bacanja, brzo treperenje svih dioda za pobedu, sporo naizmenično za promašaj).


* **AXI baferovanje:** Stalno prebacuje trenutne hardverske vrednosti u 32-bitne registre namenjene AXI magistrali.



### 4. Glavni modul (`top_module.v`)

Top-level fajl koji instancira četiri debounce filtera (tri za korisnički unos broja i jedan za taster za bacanje), modul generatora i modul glavne logike. Mapira fizičke portove FPGA čipa sa internim signalima i izvodi linije za komunikaciju sa AXI interfejsom.

---

## 💻 AXI Interfejs i mapiranje registara

Za potrebe komunikacije između FPGA logike (PL) i procesorskog dela (PS), unutar `pynq_game_logic.v` rezervisana su tri izlazna 32-bitna registra:

| Hardverski registar | Smer | Opis vrednosti |
| --- | --- | --- |
| `axi_user_num`<br> | PL $\rightarrow$ PS | Sadrži broj koji je korisnik selektovao (`0` do `7` u donja 3 bita).

 |
| `axi_rolled_num`<br> | PL $\rightarrow$ PS | Sadrži nasumično izvučeni broj sa kockice (`0` do `7` u donja 3 bita).

 |
| `axi_result`<br> | PL $\rightarrow$ PS | Status igre: `0` = Igra/bacanje u toku, `1` = POGODAK (Win), `2` = PROMAŠAJ (Loss).

 |

Ovi registri se mapiraju na **AXI GPIO** IP kor unutar Vivado Block Design-a, omogućavajući ARM procesoru da običnim čitanjem memorijske adrese (Memory-Mapped I/O) dobije trenutni status igre i vodi kompletnu statistiku.

---

## 🚀 Razvojni proces i implementacija (Vivado Flow)

### 1. Sinteza i implementacija u Vivadu

1. Kreirajte novi projekat u Vivadu i izaberite **PYNQ-Z2** ploču (ili Zynq `xc7z020clg400-1` čip).
2. Dodajte sve izvorne datoteke: `debounce_filter.v`, `lfsr_generator.v`, `pynq_game_logic.v` i `top_module.v`.


3. Kreirajte `.xdc` (constraints) fajl i mapirajte sistemski takt na pin `H16` ($125\text{ MHz}$), tastere `btn[3:0]` na pinove za tastere (`D19`, `D20`, `L20`, `L19`) i `led[3:0]` na pinove za diode (`R14`, `P14`, `N16`, `M14`).
4. Generišite Block Design, ubacite **Zynq7 Processing System** i povežite ga sa `top_module` preko AXI GPIO blokova za sva tri izlazna registra.


5. Pokrenite sintezu, implementaciju i generišite **Bitstream** (`.bit` i `.hwh` fajlove).

### 2. Povezivanje sa PYNQ softverskim nivoom (PS)

Prebacite generisani `.bit` i `.hwh` fajl na ploču. Koristeći Jupyter Notebook ili samostalnu aplikaciju pisani u Python-u ili C-u, možete pristupiti AXI GPIO subsystemu. Program na procesorskoj strani u petlji očitava memorijske adrese mapiranih registara, detektuje kraj igre kada se `axi_result` promeni, i na osnovu toga osvežava ukupan broj odigranih partija, procenat uspešnosti i trenutne rezultate na terminalu.
