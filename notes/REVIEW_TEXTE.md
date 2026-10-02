# Texte zur Durchsicht

**Erzeugt aus [`questionnaire_v1.json`](../karriko_flutter/assets/questionnaire/questionnaire_v1.json) mit `dart run tools/review_texte.dart`. Nicht von Hand ändern.**

Hier steht alles, was ich in der Fragendefinition geschrieben habe, ohne dass
es wörtlich in [`karriko-fragebogen.md`](karriko-fragebogen.md) stand. Drei
Sorten, und sie brauchen unterschiedliche Aufmerksamkeit:

| Sorte | Was zu tun ist |
|---|---|
| **Rechtliche Platzhalter** | Müssen vor dem ersten Echtbetrieb durch geprüften Text ersetzt werden. Ich habe hier nichts erfunden — es steht wörtlich `PLATZHALTER` da, damit niemand sie versehentlich für fertig hält. |
| **Ergänzte Inhalte** | Die Spezifikation nennt an diesen Stellen nur Beispiele oder gar nichts: Modulfragen, Antwortstufen, Schwellenwerte, Anlaufstellen, Berufsliste. Ich habe sinnvoll ergänzt. Alles davon ist eine Behauptung, die du prüfen solltest. |
| **Vergangenheitsformen** | Die Spezifikation formuliert überwiegend im Präsens für aktuelle Azubis. Jede `past`-Variante ist von mir. Die meisten sind mechanisch, ein paar nicht. |

Was **nicht** hier steht, ist wörtlich aus der Spezifikation übernommen und
wurde nicht angefasst.

---

## 1. Rechtliche Platzhalter

**3 Stück.** Diese Texte muss jemand schreiben, der dafür einstehen kann. Bis dahin erscheinen sie so, wie sie hier stehen — sichtbar unfertig ist besser als unsichtbar falsch.

### `anonymity.intro`

> PLATZHALTER — juristisch zu prüfen. Hier steht, was der Betrieb sieht und was nicht: welche Angaben in der Einzelansicht erscheinen, welche nur aggregiert, und ab wie vielen Bewertungen überhaupt etwas sichtbar wird.

### `anonymity.sensitive`

> PLATZHALTER — juristisch zu prüfen. Kurzfassung der Anonymitätszusage, die vor jedem sensiblen Block erneut erscheint.

### `legal.verifikation`

> PLATZHALTER — juristisch zu prüfen. Wofür der Nachweis gebraucht wird, wie lange er gespeichert bleibt, wer ihn sieht, und dass er pseudonym abgelegt wird.

## 2. Module, deren Zuschnitt ich ergänzt habe

**7 von 11 Modulen.** Abschnitt 5 der Spezifikation nennt je Modul ein bis drei Beispielfragen. Welche Fragen ein Modul tatsächlich stellt, wie lange es dauert und wann es ausgelöst wird, steht dort nicht durchgehend.

| Modul | Fragen | Teaser |
|---|---|---|
| `fachliche_qualitaet` — Fachliche Qualität | 2 | Noch zwei Fragen dazu, was du fachlich lernst? |
| `geld` — Geld und Sachleistungen | 2 | Noch zwei Fragen zu Geld und Sachleistungen? |
| `arbeitszeit` — Arbeitszeit | 4 | Noch vier Fragen zu deinen Arbeitszeiten? |
| `jugendarbeitsschutz` — Jugendarbeitsschutz | 1 | Fünf kurze Fakten zu der Zeit, als du noch keine 18 warst? |
| `gesundheit` — Gesundheit und Sicherheit | 3 | Noch drei Fragen zu Sicherheit und Belastung? |
| `berufsschule` — Berufsschule und Betrieb | 1 | Eine kurze Frage zur Berufsschule? |
| `abbruch` — Das Ende der Ausbildung | 4 | Noch vier Fragen dazu, wie es zu Ende ging? |

## 3. Fragen, die ich ergänzt oder zugeschnitten habe

**44 von 64 Fragen.** Entweder steht die Frage so nicht in der Spezifikation, oder ihr Format, ihre Bedingung oder ihre Grenzwerte sind von mir.

| Kennung | Spec | Text |
|---|---|---|
| `intro_anonymitaet` | Abschnitt 1 | Bevor es losgeht |
| `s2_startjahr` | S2 | Wann hast du dort angefangen? |
| `s2_1_endjahr` | S2 | Wann hast du aufgehört? |
| `s3_beruf` | S3 | Welchen Beruf lernst du dort? |
| `s4_lehrjahr` | S4 | In welchem Ausbildungsjahr bist du? |
| `k1_fakten` | K1 | Trifft das auf deine Ausbildung zu? |
| `k3_ueberstunden` | K3 | Wie viele Überstunden hattest du in den letzten vier Wochen ungefähr? |
| `k5_empfehlung` | K5 | Ein Freund von dir will denselben Beruf lernen. Wie wahrscheinlich würdest du ihm diesen Betrieb empfehlen? |
| `k10_belastung` | K10 | Wie oft kommst du nach der Arbeit völlig ausgelaugt nach Hause? |
| `mod_ausbilder_gespraeche` | Modul Ausbilder | Wie oft hattest du in den letzten drei Monaten ein Gespräch über deinen Stand? |
| `mod_ausbilder_kennt_stand` | Modul Ausbilder | Woran merkst du, dass dein Ausbilder deinen Ausbildungsstand kennt? |
| `mod_ausbilder_fehler` | Modul Ausbilder | Wie reagiert er auf Fehler? |
| `mod_ausbilder_erreichbar` | Abschnitt 9 | Wenn du deinen Ausbilder brauchst, erreichst du ihn? |
| `mod_fachlich_fehlende_inhalte` | Modul Fachliche Qualität | Welche Inhalte aus deinem Ausbildungsrahmenplan hast du bisher gar nicht gemacht? |
| `mod_fachlich_bekanntes` | Modul Fachliche Qualität | Wie oft arbeitest du an Aufgaben, die du schon vollständig kannst? |
| `mod_geld_verguetung` | Modul Geld | Wie viel verdienst du im Monat brutto? |
| `mod_arbeitszeit_urlaub_vorlauf` | Modul Arbeitszeit | Wie kurzfristig musst du Urlaub beantragen? |
| `mod_arbeitszeit_urlaub_abgelehnt` | Modul Arbeitszeit | Wie oft wurde dein Urlaub abgelehnt? |
| `mod_pruefung_vorbereitung` | Modul Prüfung | Wie bereitet dich der Betrieb auf die Prüfung vor? |
| `mod_pruefung_lernzeit` | Modul Prüfung | Bekommst du Lernzeit? |
| `mod_pruefung_unterricht` | Modul Prüfung | Gab es innerbetrieblichen Unterricht? |
| `mod_uebernahme_zeitpunkt` | Modul Übernahme | Wann wurde über die Übernahme gesprochen? |
| `mod_uebernahme_weggang` | Modul Übernahme | Warum bist du gegangen? |
| `mod_jas_fakten` | Modul Jugendarbeitsschutz | Als du noch keine 18 warst — traf das zu? |
| `mod_gesundheit_unterweisung` | Modul Gesundheit und Sicherheit | Gab es eine Sicherheitsunterweisung? |
| `mod_gesundheit_psa` | Modul Gesundheit und Sicherheit | Bekommst du die vorgeschriebene Schutzausrüstung? |
| `mod_gesundheit_grenze` | Modul Gesundheit und Sicherheit | Wie oft arbeitest du an der Belastungsgrenze? |
| `mod_schule_interesse` | Modul Berufsschule und Betrieb | Interessiert es im Betrieb, was du in der Schule machst? |
| `mod_konflikt_haeufigkeit` | Modul Konflikte | Wie oft gab es Situationen, die dir unangenehm waren? |
| `mod_konflikt_art` | Modul Konflikte | Worum ging es dabei? |
| `mod_konflikt_angesprochen` | Modul Konflikte | Hast du es im Betrieb angesprochen? |
| `mod_konflikt_reaktion` | Modul Konflikte | Was ist daraufhin passiert? |
| `mod_konflikt_anlaufstellen` | Modul Konflikte | Wo du Unterstützung bekommst |
| `mod_abbruch_zeitpunkt` | Modul Abbruch | Wann hast du aufgehört? |
| `mod_abbruch_wer` | Modul Abbruch | Wer hat die Sache beendet? |
| `mod_abbruch_ausschlag` | Modul Abbruch | Was hat den Ausschlag gegeben? |
| `a1_freitexte` | A1 | Was lief gut, was lief schlecht? |
| `a2_abgleich` | A2 | Am Anfang hast du die Ausbildung eher gut bewertet, deine Antworten danach klingen kritischer. Was trifft es besser? |
| `a2_1_korrektur` | A2 | Wie gut war die Ausbildung dort insgesamt? |
| `a3_tagesform` | A3 | Ganz unabhängig vom Betrieb: Wie war dein Tag heute? |
| `a3_1_verschieben` | A3 | Willst du das jetzt abschicken oder lieber in drei Tagen nochmal draufschauen? Wir speichern alles. |
| `a3_2_kleinbetrieb` | Abschnitt 10 | In einem Betrieb mit einem Azubi kann dein Chef wahrscheinlich erkennen, dass du das geschrieben hast. |
| `a4_vorschau` | A4 | So sieht deine Bewertung später öffentlich aus. |
| `a5_verifikation` | A5 | Weise dein Ausbildungsverhältnis nach |

## 4. Antwortoptionen, die ich ergänzt habe

**119 von 223 Optionen.** Die Spezifikation gibt bei den Kernfragen alle fünf Stufen wörtlich vor; bei den Modulfragen nennt sie meist nur die beiden Enden oder gar nichts. Die Punktwerte in der letzten Spalte bestimmen, wie stark eine Antwort den zugehörigen Subscore bewegt.

| Frage | Option | Beschriftung | Punkte |
|---|---|---|---|
| `mod_ausbilder_kennt_stand` | `passende_aufgaben` | Ich bekomme Aufgaben, die zu meinem Stand passen | 1,0 |
| `mod_ausbilder_kennt_stand` | `spricht_es_an` | Er spricht meinen Stand von sich aus an | 0,75 |
| `mod_ausbilder_kennt_stand` | `nur_auf_nachfrage` | Nur wenn ich selbst nachfrage | 0,5 |
| `mod_ausbilder_kennt_stand` | `merke_ich_nicht` | Merke ich eigentlich nicht | 0,25 |
| `mod_ausbilder_kennt_stand` | `kennt_ihn_nicht` | Er kennt meinen Stand nicht | 0,0 |
| `mod_ausbilder_fehler` | `sachlich` | sagt sachlich, was falsch war | 0,75 |
| `mod_ausbilder_fehler` | `genervt` | reagiert genervt, erklärt aber | 0,5 |
| `mod_ausbilder_fehler` | `vorwuerfe` | macht Vorwürfe | 0,25 |
| `mod_fachlich_fehlende_inhalte` | `keine` | keine, ich habe alles gemacht | — |
| `mod_fachlich_fehlende_inhalte` | `einzelne` | einzelne Bereiche | — |
| `mod_fachlich_fehlende_inhalte` | `groessere_teile` | größere Teile | — |
| `mod_fachlich_fehlende_inhalte` | `kenne_plan_nicht` | Ich kenne meinen Ausbildungsrahmenplan nicht | — |
| `mod_fachlich_bekanntes` | `fast_nie` | fast nie | 1,0 |
| `mod_fachlich_bekanntes` | `selten` | selten | 0,75 |
| `mod_fachlich_bekanntes` | `manchmal` | manchmal | 0,5 |
| `mod_fachlich_bekanntes` | `oft` | oft | 0,25 |
| `mod_fachlich_bekanntes` | `fast_immer` | fast immer | 0,0 |
| `mod_arbeitszeit_planbarkeit` | `fast_nie` | fast nie | 1,0 |
| `mod_arbeitszeit_planbarkeit` | `selten` | selten | 0,75 |
| `mod_arbeitszeit_planbarkeit` | `manchmal` | manchmal | 0,5 |
| `mod_arbeitszeit_planbarkeit` | `oft` | oft | 0,25 |
| `mod_arbeitszeit_planbarkeit` | `fast_immer` | fast immer | 0,0 |
| `mod_arbeitszeit_freizeit` | `nie` | nie | 1,0 |
| `mod_arbeitszeit_freizeit` | `selten` | selten | 0,75 |
| `mod_arbeitszeit_freizeit` | `manchmal` | manchmal | 0,5 |
| `mod_arbeitszeit_freizeit` | `oft` | oft | 0,25 |
| `mod_arbeitszeit_freizeit` | `staendig` | ständig | 0,0 |
| `mod_arbeitszeit_urlaub_vorlauf` | `kurzfristig_moeglich` | kurzfristig ist kein Problem | 1,0 |
| `mod_arbeitszeit_urlaub_vorlauf` | `einige_wochen` | einige Wochen vorher | 0,75 |
| `mod_arbeitszeit_urlaub_vorlauf` | `monate` | Monate vorher | 0,5 |
| `mod_arbeitszeit_urlaub_vorlauf` | `jahresplanung` | nur in der Jahresplanung | 0,25 |
| `mod_arbeitszeit_urlaub_abgelehnt` | `nie` | nie | 1,0 |
| `mod_arbeitszeit_urlaub_abgelehnt` | `einmal` | einmal | 0,5 |
| `mod_arbeitszeit_urlaub_abgelehnt` | `mehrfach` | mehrfach | 0,0 |
| `mod_pruefung_vorbereitung` | `systematisch` | systematisch und von sich aus | 1,0 |
| `mod_pruefung_vorbereitung` | `auf_nachfrage` | wenn ich danach frage | 0,5 |
| `mod_pruefung_vorbereitung` | `gar_nicht` | gar nicht | 0,0 |
| `mod_pruefung_lernzeit` | `ja_geregelt` | ja, geregelt | 1,0 |
| `mod_pruefung_lernzeit` | `auf_nachfrage` | auf Nachfrage | 0,5 |
| `mod_pruefung_lernzeit` | `nein` | nein | 0,0 |
| `mod_pruefung_unterricht` | `ja` | ja | 1,0 |
| `mod_pruefung_unterricht` | `nein` | nein | 0,0 |
| `mod_pruefung_unterricht` | `weiss_nicht` | weiß ich nicht | — |
| `mod_uebernahme_zeitpunkt` | `frueh` | mehr als ein halbes Jahr vor Ende | 1,0 |
| `mod_uebernahme_zeitpunkt` | `letzte_monate` | in den letzten Monaten | 0,66 |
| `mod_uebernahme_zeitpunkt` | `ganz_zum_schluss` | ganz zum Schluss | 0,33 |
| `mod_uebernahme_zeitpunkt` | `gar_nicht` | gar nicht | 0,0 |
| `mod_uebernahme_weggang` | `keine_uebernahme` | Ich wurde nicht übernommen | — |
| `mod_uebernahme_weggang` | `geld` | Bezahlung | — |
| `mod_uebernahme_weggang` | `perspektive` | keine Perspektive im Betrieb | — |
| `mod_uebernahme_weggang` | `umgang` | Umgang im Betrieb | — |
| `mod_uebernahme_weggang` | `arbeitszeit` | Arbeitszeiten | — |
| `mod_uebernahme_weggang` | `weiterbildung` | Ich wollte studieren oder mich weiterbilden | — |
| `mod_jas_fakten` | `berufsschultag_frei` (Karte) | Nach einem Berufsschultag mit mehr als fünf Stunden musste ich nicht mehr in den Betrieb. | — |
| `mod_jas_fakten` | `keine_arbeit_nach_20` (Karte) | Ich musste nie nach 20 Uhr arbeiten. | — |
| `mod_jas_fakten` | `keine_samstagsarbeit` (Karte) | Ich musste nie samstags arbeiten. | — |
| `mod_jas_fakten` | `pausen` (Karte) | Ich hatte immer die vorgeschriebenen Pausen. | — |
| `mod_jas_fakten` | `aerztliche_untersuchung` (Karte) | Die ärztliche Untersuchung vor Ausbildungsbeginn hat stattgefunden. | — |
| `mod_gesundheit_unterweisung` | `ja_regelmaessig` | ja, regelmäßig | — |
| `mod_gesundheit_unterweisung` | `ja_einmal` | ja, einmal am Anfang | — |
| `mod_gesundheit_unterweisung` | `nein` | nein | — |
| `mod_gesundheit_unterweisung` | `weiss_nicht` | weiß ich nicht | — |
| `mod_gesundheit_psa` | `ja_vollstaendig` | ja, vollständig | — |
| `mod_gesundheit_psa` | `teilweise` | teilweise | — |
| `mod_gesundheit_psa` | `nein` | nein | — |
| `mod_gesundheit_psa` | `nicht_noetig` | bei meiner Arbeit nicht nötig | — |
| `mod_gesundheit_grenze` | `fast_nie` | fast nie | 1,0 |
| `mod_gesundheit_grenze` | `selten` | selten | 0,75 |
| `mod_gesundheit_grenze` | `manchmal` | manchmal | 0,5 |
| `mod_gesundheit_grenze` | `oft` | oft | 0,25 |
| `mod_gesundheit_grenze` | `fast_taeglich` | fast täglich | 0,0 |
| `mod_schule_interesse` | `ja_aktiv` | ja, es wird von sich aus danach gefragt | 1,0 |
| `mod_schule_interesse` | `wenn_ich_erzaehle` | nur wenn ich selbst davon erzähle | 0,5 |
| `mod_schule_interesse` | `nein` | nein, das ist dort kein Thema | 0,0 |
| `mod_schule_interesse` | `weiss_nicht` | weiß ich nicht | — |
| `mod_konflikt_haeufigkeit` | `nie` | nie | — |
| `mod_konflikt_haeufigkeit` | `einmal` | einmal | — |
| `mod_konflikt_haeufigkeit` | `mehrfach` | mehrfach | — |
| `mod_konflikt_haeufigkeit` | `regelmaessig` | regelmäßig | — |
| `mod_konflikt_haeufigkeit` | `keine_angabe` | möchte ich nicht sagen | — |
| `mod_konflikt_art` | `anschreien` | lautes Anschreien oder Beschimpfen | — |
| `mod_konflikt_art` | `herabwuerdigung` | Herabwürdigung vor anderen | — |
| `mod_konflikt_art` | `ausgrenzung` | Ausgrenzung | — |
| `mod_konflikt_art` | `koerperlich` | körperliche Übergriffe | — |
| `mod_konflikt_art` | `sexuell` | sexuelle Belästigung | — |
| `mod_konflikt_art` | `diskriminierung` | Diskriminierung | — |
| `mod_konflikt_art` | `keine_angabe` | möchte ich nicht sagen | — |
| `mod_konflikt_angesprochen` | `ja` | ja | — |
| `mod_konflikt_angesprochen` | `nein` | nein | — |
| `mod_konflikt_angesprochen` | `keine_angabe` | möchte ich nicht sagen | — |
| `mod_konflikt_reaktion` | `geaendert` | Es hat sich etwas geändert | — |
| `mod_konflikt_reaktion` | `nichts` | Es ist nichts passiert | — |
| `mod_konflikt_reaktion` | `schlechter` | Danach wurde es für mich schlechter | — |
| `mod_konflikt_reaktion` | `keine_angabe` | möchte ich nicht sagen | — |
| `mod_abbruch_zeitpunkt` | `probezeit` | in der Probezeit | — |
| `mod_abbruch_zeitpunkt` | `jahr_1` | im 1. Ausbildungsjahr | — |
| `mod_abbruch_zeitpunkt` | `jahr_2` | im 2. Ausbildungsjahr | — |
| `mod_abbruch_zeitpunkt` | `jahr_3_4` | im 3. oder 4. Ausbildungsjahr | — |
| `mod_abbruch_wer` | `ich` | ich | — |
| `mod_abbruch_wer` | `betrieb` | der Betrieb | — |
| `mod_abbruch_wer` | `gemeinsam` | in gegenseitigem Einvernehmen | — |
| `mod_abbruch_ausschlag` | `anleitung` | zu wenig Anleitung | — |
| `mod_abbruch_ausschlag` | `umgang` | Umgang im Betrieb | — |
| `mod_abbruch_ausschlag` | `belastung` | Belastung oder Arbeitszeiten | — |
| `mod_abbruch_ausschlag` | `geld` | Bezahlung | — |
| `mod_abbruch_ausschlag` | `falscher_beruf` | der Beruf war nichts für mich | — |
| `mod_abbruch_ausschlag` | `schule` | die Berufsschule | — |
| `a2_abgleich` | `frueh` | Das erste Urteil trifft es besser | — |
| `a2_abgleich` | `detail` | Die späteren Antworten treffen es besser | — |
| `a2_abgleich` | `neu` | Ich möchte es neu einstellen | — |
| `a3_tagesform` | `sehr_gut` | sehr gut | — |
| `a3_tagesform` | `gut` | gut | — |
| `a3_tagesform` | `mittel` | geht so | — |
| `a3_tagesform` | `schlecht` | schlecht | — |
| `a3_tagesform` | `sehr_schlecht` | sehr schlecht | — |
| `a3_1_verschieben` | `jetzt` | Jetzt abschicken | — |
| `a3_1_verschieben` | `in_drei_tagen` | In drei Tagen nochmal draufschauen | — |
| `a3_2_kleinbetrieb` | `sofort` | Trotzdem sofort veröffentlichen | — |
| `a3_2_kleinbetrieb` | `nach_ausbildungsende` | Erst nach Ende meiner Ausbildung veröffentlichen | — |

## 5. Vergangenheitsformen

**70 Texte, bei denen sich die Zeitform unterscheidet.** Weitere 252 Texte tragen in beiden Zeitformen denselben Wortlaut — dort gibt es nichts umzuformen, etwa bei „Probezeit" oder „weiß ich nicht".

Die Zeitform folgt allein aus S1: Wer noch in der Ausbildung ist, liest die linke Spalte, alle anderen die rechte.

| Stelle | Präsens (wörtlich aus der Spezifikation) | Vergangenheit (von mir) |
|---|---|---|
| `modul:fachliche_qualitaet.teaser` | Noch zwei Fragen dazu, was du fachlich lernst? | Noch zwei Fragen dazu, was du fachlich gelernt hast? |
| `s3_beruf.text` | Welchen Beruf lernst du dort? | Welchen Beruf hast du dort gelernt? |
| `s4_lehrjahr.text` | In welchem Ausbildungsjahr bist du? | In welchem Ausbildungsjahr hast du aufgehört? |
| `s5_betriebsgroesse.text` | Wie groß ist der Betrieb ungefähr? | Wie groß war der Betrieb ungefähr? |
| `s6_azubizahl.text` | Wie viele Azubis gibt es dort insgesamt? | Wie viele Azubis gab es dort insgesamt? |
| `s7_ausbildungsform.text` | Wie läuft deine Ausbildung? | Wie lief deine Ausbildung? |
| `s8_arbeitsalltag.text` | Was trifft auf deinen Arbeitsalltag zu? | Was traf auf deinen Arbeitsalltag zu? |
| `s10_berufsschule_form.text` | Wie ist deine Berufsschule organisiert? | Wie war deine Berufsschule organisiert? |
| `k1_fakten.text` | Trifft das auf deine Ausbildung zu? | Traf das auf deine Ausbildung zu? |
| `k1_fakten.k1_1_ausbildungsplan` | Es gibt einen schriftlichen Ausbildungsplan, den ich kenne. | Es gab einen schriftlichen Ausbildungsplan, den ich kannte. |
| `k1_fakten.k1_2_ansprechpartner` | Es gibt eine feste Person, an die ich mich bei Fragen wenden kann. | Es gab eine feste Person, an die ich mich bei Fragen wenden konnte. |
| `k1_fakten.k1_3_berichtsheft` | Ich darf mein Berichtsheft während der Arbeitszeit schreiben. | Ich durfte mein Berichtsheft während der Arbeitszeit schreiben. |
| `k1_fakten.k1_4_berufsschule` | Ich werde für alle Berufsschultage vollständig freigestellt. | Ich wurde für alle Berufsschultage vollständig freigestellt. |
| `k1_fakten.k1_5_ausruestung` | Arbeitskleidung und Werkzeug stellt der Betrieb. | Arbeitskleidung und Werkzeug stellte der Betrieb. |
| `k1_fakten.k1_6_gespraeche` | Es gibt regelmäßige Gespräche darüber, wie es bei mir läuft. | Es gab regelmäßige Gespräche darüber, wie es bei mir lief. |
| `k2_ausbildungsfremd.text` | Wie viel Zeit ging dafür in den letzten vier Wochen ungefähr drauf? | Wie viel Zeit ging dafür in einem typischen Monat ungefähr drauf? |
| `k3_ueberstunden.text` | Wie viele Überstunden hattest du in den letzten vier Wochen ungefähr? | Wie viele Überstunden hattest du in einem typischen Monat ungefähr? |
| `k3_ueberstunden.keine` | ich mache keine Überstunden | ich habe keine Überstunden gemacht |
| `k3_1_ausgleich.text` | Was passiert damit? | Was passierte damit? |
| `k3_1_ausgleich.ausgezahlt` | werden ausgezahlt | wurden ausgezahlt |
| `k4_erreichbarkeit.text` | Wenn du bei einer Aufgabe nicht weiterkommst, ist dann jemand da, den du fragen kannst? | Wenn du bei einer Aufgabe nicht weiterkamst, war dann jemand da, den du fragen konntest? |
| `k6_gesamt.text` | Und wie gut ist die Ausbildung dort insgesamt? | Und wie gut war die Ausbildung dort insgesamt? |
| `k7_anleitung.text` | Wenn dir jemand etwas Neues zeigt, wie läuft das ab? | Wenn dir jemand etwas Neues zeigte, wie lief das ab? |
| `k7_anleitung.in_ruhe` | wird mir in Ruhe erklärt und ich darf üben | wurde mir in Ruhe erklärt und ich durfte üben |
| `k7_anleitung.in_eile` | wird erklärt, aber oft in Eile | wurde erklärt, aber oft in Eile |
| `k7_anleitung.einmal_vorgemacht` | wird einmal vorgemacht, dann muss es sitzen | wurde einmal vorgemacht, dann musste es sitzen |
| `k7_anleitung.selbst_suchen` | ich muss mir das meiste selbst zusammensuchen | ich musste mir das meiste selbst zusammensuchen |
| `k7_anleitung.keine_einweisung` | ich bekomme gar keine Einweisung | ich bekam gar keine Einweisung |
| `k8_lernwert.text` | Wie viel von dem, was du im Betrieb machst, bringt dich in deinem Beruf wirklich weiter? | Wie viel von dem, was du im Betrieb gemacht hast, hat dich in deinem Beruf wirklich weitergebracht? |
| `k9_umgang.text` | Wie reden die Leute im Betrieb mit dir? | Wie redeten die Leute im Betrieb mit dir? |
| `k10_belastung.text` | Wie oft kommst du nach der Arbeit völlig ausgelaugt nach Hause? | Wie oft kamst du nach der Arbeit völlig ausgelaugt nach Hause? |
| `k11_planung.text` | Weißt du, was in den nächsten Monaten bei dir dran ist, welche Abteilungen oder Inhalte? | Wusstest du, was in den nächsten Monaten bei dir dran war, welche Abteilungen oder Inhalte? |
| `k11_planung.klar_geregelt` | ja, das ist klar geregelt | ja, das war klar geregelt |
| `k11_planung.spontan` | nein, das ergibt sich spontan | nein, das ergab sich spontan |
| `k11_planung.immer_dasselbe` | nein, ich mache seit Monaten dasselbe | nein, ich machte über Monate dasselbe |
| `k12_prioritaeten.text` | Was zählt für dich am meisten? | Was zählte für dich am meisten? |
| `k12_prioritaeten.fachlich` | Was ich fachlich lerne | Was ich fachlich gelernt habe |
| `k12_prioritaeten.umgang` | Wie mit mir umgegangen wird | Wie mit mir umgegangen wurde |
| `mod_ausbilder_gespraeche.text` | Wie oft hattest du in den letzten drei Monaten ein Gespräch über deinen Stand? | Wie oft hattest du in einem typischen Vierteljahr ein Gespräch über deinen Stand? |
| `mod_ausbilder_kennt_stand.text` | Woran merkst du, dass dein Ausbilder deinen Ausbildungsstand kennt? | Woran hast du gemerkt, dass dein Ausbilder deinen Ausbildungsstand kennt? |
| `mod_ausbilder_kennt_stand.passende_aufgaben` | Ich bekomme Aufgaben, die zu meinem Stand passen | Ich bekam Aufgaben, die zu meinem Stand passten |
| `mod_ausbilder_kennt_stand.spricht_es_an` | Er spricht meinen Stand von sich aus an | Er sprach meinen Stand von sich aus an |
| `mod_ausbilder_kennt_stand.nur_auf_nachfrage` | Nur wenn ich selbst nachfrage | Nur wenn ich selbst nachfragte |
| `mod_ausbilder_kennt_stand.merke_ich_nicht` | Merke ich eigentlich nicht | Habe ich eigentlich nicht gemerkt |
| `mod_ausbilder_kennt_stand.kennt_ihn_nicht` | Er kennt meinen Stand nicht | Er kannte meinen Stand nicht |
| `mod_ausbilder_fehler.text` | Wie reagiert er auf Fehler? | Wie reagierte er auf Fehler? |
| `mod_ausbilder_fehler.erklaert_nochmal` | erklärt es nochmal | erklärte es nochmal |
| `mod_ausbilder_fehler.sachlich` | sagt sachlich, was falsch war | sagte sachlich, was falsch war |
| `mod_ausbilder_fehler.genervt` | reagiert genervt, erklärt aber | reagierte genervt, erklärte aber |
| `mod_ausbilder_fehler.vorwuerfe` | macht Vorwürfe | machte Vorwürfe |
| `mod_ausbilder_fehler.wird_laut` | wird laut | wurde laut |
| `mod_ausbilder_erreichbar.text` | Wenn du deinen Ausbilder brauchst, erreichst du ihn? | Wenn du deinen Ausbilder brauchtest, erreichtest du ihn? |
| `mod_fachlich_fehlende_inhalte.text` | Welche Inhalte aus deinem Ausbildungsrahmenplan hast du bisher gar nicht gemacht? | Welche Inhalte aus deinem Ausbildungsrahmenplan hast du gar nicht gemacht? |
| `mod_fachlich_fehlende_inhalte.kenne_plan_nicht` | Ich kenne meinen Ausbildungsrahmenplan nicht | Ich kannte meinen Ausbildungsrahmenplan nicht |
| `mod_fachlich_bekanntes.text` | Wie oft arbeitest du an Aufgaben, die du schon vollständig kannst? | Wie oft hast du an Aufgaben gearbeitet, die du schon vollständig konntest? |
| `mod_geld_verguetung.text` | Wie viel verdienst du im Monat brutto? | Wie viel hast du im Monat brutto verdient? |
| `mod_geld_uebernimmt.text` | Was übernimmt der Betrieb? | Was hat der Betrieb übernommen? |
| `mod_arbeitszeit_planbarkeit.text` | Wie oft weißt du weniger als eine Woche vorher, wann du arbeitest? | Wie oft wusstest du weniger als eine Woche vorher, wann du arbeitest? |
| `mod_arbeitszeit_freizeit.text` | Wie oft wirst du in deiner Freizeit dienstlich kontaktiert? | Wie oft wurdest du in deiner Freizeit dienstlich kontaktiert? |
| `mod_arbeitszeit_urlaub_vorlauf.text` | Wie kurzfristig musst du Urlaub beantragen? | Wie kurzfristig musstest du Urlaub beantragen? |
| `mod_arbeitszeit_urlaub_vorlauf.kurzfristig_moeglich` | kurzfristig ist kein Problem | kurzfristig war kein Problem |
| `mod_pruefung_vorbereitung.text` | Wie bereitet dich der Betrieb auf die Prüfung vor? | Wie hat dich der Betrieb auf die Prüfung vorbereitet? |
| `mod_pruefung_vorbereitung.auf_nachfrage` | wenn ich danach frage | wenn ich danach fragte |
| `mod_pruefung_lernzeit.text` | Bekommst du Lernzeit? | Hast du Lernzeit bekommen? |
| `mod_gesundheit_psa.text` | Bekommst du die vorgeschriebene Schutzausrüstung? | Hast du die vorgeschriebene Schutzausrüstung bekommen? |
| `mod_gesundheit_grenze.text` | Wie oft arbeitest du an der Belastungsgrenze? | Wie oft hast du an der Belastungsgrenze gearbeitet? |
| `mod_schule_interesse.text` | Interessiert es im Betrieb, was du in der Schule machst? | Hat es im Betrieb interessiert, was du in der Schule machst? |
| `mod_schule_interesse.ja_aktiv` | ja, es wird von sich aus danach gefragt | ja, es wurde von sich aus danach gefragt |
| `mod_schule_interesse.wenn_ich_erzaehle` | nur wenn ich selbst davon erzähle | nur wenn ich selbst davon erzählte |
| `mod_schule_interesse.nein` | nein, das ist dort kein Thema | nein, das war dort kein Thema |

---

*Erzeugt am 2026-09-28 aus Version 1 der Definition.*
