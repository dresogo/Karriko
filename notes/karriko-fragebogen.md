# Karriko: Bewertungsfragebogen für Azubis

Spezifikation für die Umsetzung. Enthält Fragenpool, Filterlogik, Formate, Scoring und die psychologische Begründung hinter jedem Baustein.

---

## 1. Die sechs Prinzipien, nach denen gebaut wird

**Fakten vor Gefühlen.** Der Bogen startet nicht mit "Wie zufrieden bist du?", sondern mit überprüfbarem Verhalten: Überstunden, Ansprechpartner, Berichtsheft. Konkrete Verhaltensfragen erzeugen weniger Verzerrung als Einstellungsfragen, weil sich Fakten schlechter umdeuten lassen. Wer zuerst Zahlen nennt, rutscht seltener in eine reine Wutbewertung.

**Das Gesamturteil kommt zweimal.** Einmal früh, bevor Detailfragen die Stimmung färben, und einmal am Ende als Abgleich. Die Reihenfolge von Fragen verschiebt Zufriedenheitswerte messbar: Ärgerthemen vorweg drücken das Urteil, Erfolgsthemen heben es. Das frühe Urteil wird veröffentlicht, das späte dient als Konsistenzprüfung und Reue-Check.

**Normalisierende Einleitungen.** Vor heiklen Fragen steht ein Satz, der die unerwünschte Antwort als normal markiert ("Fast jeder Azubi macht ab und zu Aufgaben, die nichts mit der Ausbildung zu tun haben"). Das senkt soziale Erwünschtheit deutlich zuverlässiger als jede Beteuerung von Anonymität.

**Anonymität wird konkret und wiederholt zugesagt.** Nicht einmal im Intro, sondern erneut direkt vor jedem sensiblen Block, und zwar mit der genauen Aussage, was der Betrieb sieht und was nicht.

**Regler sparsam.** In experimentellen Vergleichen erhöhen Slider auf Mobilgeräten die Abbruchquote erheblich, verzerren die Werteverteilung und kosten Zeit; visuelle Analogskalen und normale Auswahlfelder zeigen diese Effekte nicht. Dazu kommt ein Ankereffekt auf runde Werte, sobald eine Zahl live mitläuft. Es gibt deshalb genau zwei Regler im ganzen Bogen, beide ohne Zahlenanzeige und ohne voreingestellte Position.

**Abwechslung gegen Durchklicken.** Keine zwei Matrizen hintereinander, eine Frage pro Bildschirm, wechselnde Formate, gemischte Polung. Gleichförmige Blöcke laden zum Straightlining ein.

---

## 2. Ablauf

| Phase | Inhalt | Dauer | Pflicht |
|---|---|---|---|
| 0 | Steuerfragen | 45 Sek | ja |
| 1 | Kern: Fakten, Gesamturteil, fünf Dimensionen, Prioritäten-Ranking | 2,5 Min | ja |
| 2 | Vertiefung: drei selbst gewählte Themen plus automatisch passende Module | 3 bis 6 Min | freiwillig, einzeln abwählbar |
| 3 | Freitexte, Abgleich, Vorschau, Freigabe | 1,5 Min | ja |

Nach Phase 1 ist eine veröffentlichungsfähige Bewertung vorhanden. Phase 2 wird nicht als Pflichtstrecke angekündigt, sondern modulweise angeboten: "Noch vier Fragen zu deinem Ausbilder? Dauert 40 Sekunden." Das hält die Abbruchquote niedrig und liefert trotzdem Tiefe von denen, die etwas zu sagen haben.

---

## 3. Phase 0: Steuerfragen

Diese Antworten entscheiden, welche Fragen später überhaupt erscheinen.

| ID | Frage | Format | Steuert |
|---|---|---|---|
| S1 | Wo stehst du gerade? Optionen: Ich bin noch in der Ausbildung / Ich habe dort ausgelernt und bin geblieben / Ich habe dort ausgelernt und bin gegangen / Ich habe die Ausbildung dort vorzeitig beendet | vier große Kacheln | Zeitform aller Fragen, Übernahmemodul, Abbruchmodul |
| S2 | Wann hast du dort angefangen? (Jahr) plus bei S1 = beendet: Wann hast du aufgehört? | Dropdown | Aktualitätsgewichtung, Archivkennzeichnung ab vier Jahren |
| S3 | Welchen Beruf lernst du dort? | Suchfeld mit Autocomplete auf der Berufsliste der BA | Branchenvergleich, Fachmodule |
| S4 | In welchem Ausbildungsjahr bist du? Optionen: Probezeit / 1. / 2. / 3. / 4. | Segmentierte Auswahl | Prüfungsmodul erst ab 2. Jahr, Übernahmemodul erst im letzten Jahr |
| S5 | Wie groß ist der Betrieb ungefähr? Optionen: unter 10 / 10 bis 49 / 50 bis 249 / 250 und mehr / weiß ich nicht | Auswahl | Fragen zur Ausbildungsabteilung, Anonymitätshinweis |
| S6 | Wie viele Azubis gibt es dort insgesamt? Optionen: nur ich / 2 bis 5 / 6 bis 20 / mehr / weiß ich nicht | Auswahl | Azubi-Zusammenhalt, Veröffentlichungsschutz bei Einzelfällen |
| S7 | Wie läuft deine Ausbildung? Optionen: klassisch dual / duales Studium / Teilzeit / Verbundausbildung | Auswahl | Modulauswahl |
| S8 | Was trifft auf deinen Arbeitsalltag zu? | Wischkarten, links weg / rechts trifft zu: Schichtarbeit, Wochenenddienste, Montage oder Auswärtstätigkeit, direkter Kundenkontakt, viel Fahrerei, körperlich schwere Arbeit, Arbeit am Bildschirm | Module Arbeitszeit, Reise, Gesundheit |
| S9 | Warst du während der Ausbildung zeitweise noch keine 18? | Ja / Nein | Modul Jugendarbeitsschutz |
| S10 | Wie ist deine Berufsschule organisiert? Optionen: Blockunterricht / einzelne Schultage / überwiegend online | Auswahl | Freistellungsfragen |

Wischkarten bei S8 sind bewusst auf Fakten begrenzt. Für Bewertungen eignet sich das Format nicht, weil die Wischgeste zum schnellen Durchziehen verführt.

---

## 4. Phase 1: Kern

### Block A, Fakten

**K1. Sechs Wischkarten, je Ja / Nein / Weiß ich nicht**

Einleitung: "Erst ein paar Fakten. Dauert 30 Sekunden."

1. Es gibt einen schriftlichen Ausbildungsplan, den ich kenne.
2. Es gibt eine feste Person, an die ich mich bei Fragen wenden kann.
3. Ich darf mein Berichtsheft während der Arbeitszeit schreiben.
4. Ich werde für alle Berufsschultage vollständig freigestellt.
5. Arbeitskleidung und Werkzeug stellt der Betrieb.
6. Es gibt regelmäßige Gespräche darüber, wie es bei mir läuft.

**K2. Ausbildungsfremde Tätigkeiten**

Einleitung: "Fast jeder Azubi macht ab und zu Sachen, die mit der Ausbildung nichts zu tun haben. Kaffee holen, Auto waschen, privates Zeug für den Chef."

Frage: "Wie viel Zeit ging dafür in den letzten vier Wochen ungefähr drauf?"
Optionen: gar nichts / unter einer Stunde pro Woche / ein bis drei Stunden pro Woche / mehr als drei Stunden pro Woche / mehr als die Hälfte meiner Arbeitszeit

**K3. Überstunden**

Frage: "Wie viele Überstunden hattest du in den letzten vier Wochen ungefähr?"
Format: Stepper in Fünferschritten, Feld "weiß ich nicht genau", Feld "ich mache keine Überstunden"

Folgefrage nur wenn größer null: "Was passiert damit?" Optionen: werden ausgezahlt / abgefeiert / teils teils / gar nichts / weiß ich nicht

**K4. Erreichbarkeit der Anleitung**

Frage: "Wenn du bei einer Aufgabe nicht weiterkommst, ist dann jemand da, den du fragen kannst?"
Optionen: eigentlich immer / meistens / ungefähr die Hälfte der Zeit / selten / praktisch nie

K4 bildet später mit einer Modulfrage ein Konsistenzpaar.

### Block B, Gesamturteil vor der Detailfärbung

**K5. Weiterempfehlung**

Frage: "Ein Freund von dir will denselben Beruf lernen. Wie wahrscheinlich würdest du ihm diesen Betrieb empfehlen?"
Format: elf Kacheln von 0 bis 10, mit Beschriftung nur an den Enden.

Die Formulierung über eine dritte Person ist Absicht. Sie verschiebt die Frage von "Wie geht es mir?" zu "Was rate ich jemandem?" und dämpft den Einfluss der Tagesstimmung.

**K6. Gesamtqualität**

Frage: "Und wie gut ist die Ausbildung dort insgesamt?"
Format: Regler ohne Zahlenanzeige, kein Startwert, Griff erscheint erst bei Berührung, Beschriftung links "schlecht" und rechts "sehr gut", intern 0 bis 100.

Dies ist einer der beiden Regler im Bogen. Ohne sichtbare Zahl entfällt das Einrasten auf 50 oder 75.

### Block C, fünf Dimensionen, je eine Frage pro Bildschirm

Alle fünfstufig mit ausformulierten Antworten statt Zahlen, Polung gemischt.

**K7 Anleitung:** "Wenn dir jemand etwas Neues zeigt, wie läuft das ab?"
Optionen: wird mir in Ruhe erklärt und ich darf üben / wird erklärt, aber oft in Eile / wird einmal vorgemacht, dann muss es sitzen / ich muss mir das meiste selbst zusammensuchen / ich bekomme gar keine Einweisung

**K8 Lernwert:** "Wie viel von dem, was du im Betrieb machst, bringt dich in deinem Beruf wirklich weiter?"
Optionen: fast alles / das meiste / etwa die Hälfte / eher wenig / fast nichts

**K9 Umgang:** "Wie reden die Leute im Betrieb mit dir?"
Optionen: auf Augenhöhe, wie mit einem Kollegen / überwiegend freundlich / sachlich, mehr nicht / oft von oben herab / respektlos

**K10 Belastung, umgekehrt gepolt:** "Wie oft kommst du nach der Arbeit völlig ausgelaugt nach Hause?"
Optionen: fast nie / selten / manchmal / oft / fast täglich

**K11 Planung:** "Weißt du, was in den nächsten Monaten bei dir dran ist, welche Abteilungen oder Inhalte?"
Optionen: ja, das ist klar geregelt / ungefähr / nur kurzfristig / nein, das ergibt sich spontan / nein, ich mache seit Monaten dasselbe

### Block D, Prioritäten

**K12. Was zählt für dich am meisten?**

Format: acht Karten, Drag and Drop, die drei wichtigsten nach oben ziehen.

Karten: Was ich fachlich lerne / Wie mit mir umgegangen wird / Geld und Sachleistungen / Arbeitszeiten und freie Zeit / Mein Ausbilder / Vorbereitung auf die Prüfung / Übernahme und Zukunft / Stimmung im Team

Zwei Funktionen: Die Auswahl steuert, welche drei Vertiefungsmodule angeboten werden. Und sie liefert individuelle Gewichte für den Gesamtscore, angelehnt an das Doppelskalen-Prinzip aus der BIBB-Auszubildendenbefragung, bei dem Wichtigkeit und Erfüllung getrennt erhoben werden. Das entkoppelt die Bewertung vom Affekt, ohne fünfzig Zusatzfragen zu kosten.

---

## 5. Phase 2: Module

Angeboten werden die drei aus K12 gewählten Themen plus alle automatisch getriggerten Module. Jedes Modul ist einzeln überspringbar und zeigt vorab die Anzahl der Fragen.

| Modul | Trigger | Beispielfragen |
|---|---|---|
| Ausbilder | K12 oder K4 schlechter als "meistens" | Wie oft hattest du in den letzten drei Monaten ein Gespräch über deinen Stand? Stepper 0 bis 12. Woran merkst du, dass dein Ausbilder deinen Ausbildungsstand kennt? Auswahl. Wie reagiert er auf Fehler? Fünf ausformulierte Optionen von "erklärt es nochmal" bis "wird laut". |
| Fachliche Qualität | K12 oder K8 schwach | Welche Inhalte aus deinem Ausbildungsrahmenplan hast du bisher gar nicht gemacht? Mehrfachauswahl, berufsabhängig. Wie oft arbeitest du an Aufgaben, die du schon vollständig kannst? |
| Geld | K12 | Vergütung pro Monat brutto, Zahleneingabe, optional. Was übernimmt der Betrieb? Mehrfachauswahl: Fahrtkosten, Schulmaterial, Prüfungsgebühren, Unterkunft bei Blockschule, Führerschein, nichts davon |
| Arbeitszeit | K12, S8 Schicht oder Wochenende, K3 hohe Überstunden | Wie oft weißt du weniger als eine Woche vorher, wann du arbeitest? Wie oft wirst du in deiner Freizeit dienstlich kontaktiert? Wie kurzfristig musst du Urlaub beantragen, und wie oft wurde er abgelehnt? |
| Prüfung | S4 ab 2. Jahr oder ausgelernt | Wie bereitet dich der Betrieb auf die Prüfung vor? Bekommst du Lernzeit? Gab es innerbetrieblichen Unterricht? |
| Übernahme | S4 letztes Jahr, oder S1 ausgelernt | Wann wurde über die Übernahme gesprochen? Auswahl nach Zeitpunkt. Bei Ehemaligen: Warum bist du gegangen? Mehrfachauswahl ohne Freitextzwang. |
| Jugendarbeitsschutz | S9 = ja | Fakten-Wischkarten zu Berufsschultag, Arbeit nach 20 Uhr, Samstagsarbeit, Pausen, ärztlicher Untersuchung |
| Gesundheit und Sicherheit | S8 körperlich schwer oder K10 "oft" bzw. "fast täglich" | Gab es eine Sicherheitsunterweisung? Bekommst du die vorgeschriebene Schutzausrüstung? Wie oft arbeitest du an der Belastungsgrenze? |
| Berufsschule und Betrieb | immer, kurz | Interessiert es im Betrieb, was du in der Schule machst? Drei Optionen plus "weiß ich nicht". Wird getrennt vom Betriebsscore ausgewiesen. |
| Konflikte und Grenzen | K9 schlechter als "sachlich", oder aktive Auswahl über ein Gate | siehe unten |
| Abbruch | S1 = vorzeitig beendet | siehe unten |

### Modul Konflikte, Sonderbehandlung

Wird nie unangekündigt eingeblendet. Davor steht ein Gate: "Es gibt noch einen Bereich, in dem es um unangenehme Erfahrungen geht. Vier Fragen, du kannst jede einzeln überspringen." Zwei Schaltflächen: "Zeig mir das" und "Nein danke".

Direkt darüber die Anonymitätszusage in konkreter Form: welche Angaben der Betrieb sieht, welche nicht, und ab wann Bewertungen sichtbar werden.

Fragen mit normalisierender Einleitung, Antwortoptionen grob gestuft statt exakt, damit ehrliche Antworten kein Risiko erzeugen. Am Ende des Moduls unabhängig von den Antworten ein Hinweis auf Anlaufstellen: Ausbildungsberatung der Kammer, JAV, Gewerkschaftsberatung.

### Modul Abbruch

Ton der Fragen ohne Schuldzuweisung, weil Abbrecher die emotional aufgeladenste Gruppe sind und hier die meisten Rachebewertungen entstehen.

Einleitung: "Ausbildungen werden aus ganz unterschiedlichen Gründen beendet, oft liegt es nicht nur an einer Seite."

Fragen: Wann hast du aufgehört? Wer hat die Sache beendet? Was hat den Ausschlag gegeben, Mehrfachauswahl inklusive "Gründe, die nichts mit dem Betrieb zu tun hatten". Danach: "Gab es etwas, das der Betrieb gut gemacht hat?" Diese Frage ist kein Beschwichtigungsversuch, sondern erzwingt eine differenzierte Erinnerung und senkt die Extremität des Gesamturteils.

---

## 6. Phase 3: Abschluss

**A1. Zwei getrennte Freitexte**

"Was lief gut?" und "Was lief schlecht?", beide mit Mindestlänge null, beide sichtbar nebeneinander angekündigt. Zwei Felder statt eines erzwingen den Blick auf beide Seiten.

Platzhalter im Feld statt Regeltext darüber: "Schreib, wie du es erlebt hast. Keine Namen von Kollegen, keine Behauptungen, die du nicht belegen kannst."

Unter dem Feld ein Satz, kurz und ohne Drohton: "Deine Meinung darfst du frei sagen. Falsche Tatsachenbehauptungen und Beleidigungen müssen wir löschen."

Das ist die rechtlich entscheidende Stelle. Werturteile sind von der Meinungsfreiheit gedeckt, unwahre Tatsachenbehauptungen nicht. Der Unterschied liegt in der Formulierung, und genau dort setzt der Platzhalter an: "Ich hatte das Gefühl, dass..." ist sicher, "Der Chef hat X unterschlagen" ist es nicht.

**A2. Abgleich statt Kontrollfrage**

Der berechnete Detailwert wird mit K6 verglichen. Weichen sie um mehr als einen definierten Schwellenwert ab, erscheint eine ruhige Rückfrage:

"Am Anfang hast du die Ausbildung eher gut bewertet, deine Antworten danach klingen kritischer. Was trifft es besser?" Zwei Optionen plus ein neuer Regler.

Das ersetzt plumpe Aufmerksamkeitstests, die erwachsene Nutzer als Gängelung empfinden, und liefert gleichzeitig eine echte Selbstkorrektur.

**A3. Tagesform, nur intern**

"Ganz unabhängig vom Betrieb: Wie war dein Tag heute?" Fünf Stufen.

Zwei Verwendungen. Erstens als Kovariate in der Auswertung. Zweitens als Auslöser: Wenn der Tag sehr schlecht war und die Bewertung im extremen Bereich liegt, erscheint ein Angebot statt einer Sperre: "Willst du das jetzt abschicken oder lieber in drei Tagen nochmal draufschauen? Wir speichern alles." Beide Wege bleiben offen, niemand wird bevormundet.

**A4. Vorschau**

"So sieht deine Bewertung später öffentlich aus." Die echte Profilansicht, mit allem was sichtbar wird, und darunter aufgelistet, was nicht sichtbar wird. Jeder Block einzeln zurücknehmbar.

Da auf Karriko Einzelbewertungen anklickbar sind, ist dieser Schritt nicht optional. Ohne ihn entsteht später genau das Vertrauensproblem, das die Plattform eigentlich lösen will.

**A5. Freigabe und Verifikation**

Nachweis des Ausbildungsverhältnisses, pseudonym gespeichert. Hintergrund: Nach der Hamburger Rechtsprechung muss ein bewerteter Betrieb prüfen können, ob überhaupt ein geschäftlicher Kontakt bestand; geschwärzte Unterlagen allein reichten dem OLG nicht. Ohne einen belastbaren Verifikationsprozess ist jede kritische Bewertung löschungsgefährdet, und die Plattform verliert genau die Inhalte, für die Azubis sie nutzen.

---

## 7. Formatwahl im Überblick

| Format | Eingesetzt bei | Warum |
|---|---|---|
| Wischkarten | S8, K1, Jugendarbeitsschutz | schnell und spielerisch, aber nur für Fakten mit Ja/Nein |
| Regler ohne Zahl | K6 und der Korrekturregler in A2 | nur zwei Stück, weil Slider auf Mobilgeräten Abbrüche und Verzerrung erzeugen |
| Elf Kacheln | K5 | Standard für Weiterempfehlung, vergleichbar, kein Wischen nötig |
| Fünf ausformulierte Optionen | alle Dimensionsfragen | verbale Anker sind eindeutiger als Zahlen und mindern Zustimmungstendenz |
| Stepper | Überstunden, Gesprächshäufigkeit | Zahlen, die der Azubi wirklich weiß |
| Drag and Drop | K12 | Bewegung an der Stelle, wo Ordnen inhaltlich Sinn ergibt |
| Mehrfachauswahl | Module | schneller als Einzelfragen, wenn es um Aufzählungen geht |
| Freitext | A1 | zwei Felder statt eins |

---

## 8. Scoring und Veröffentlichung

**Sechs Subscores** auf einer Skala von 1,0 bis 5,0: Fachliche Qualität, Betreuung, Umgang, Arbeitszeit und Belastung, Vergütung und Leistungen, Perspektive. Berufsschule wird separat ausgewiesen und fließt nicht in den Betriebsscore ein.

**Gesamtscore** als gewichtetes Mittel. Die Gewichte entstehen aus den aggregierten K12-Prioritäten aller Bewerter dieses Betriebs, mit einer Untergrenze pro Dimension, damit kein Bereich ganz herausfällt.

**Schrumpfung gegen Ausreißer.** Der angezeigte Score eines Betriebs wird bei wenigen Bewertungen in Richtung Branchenmittel gezogen und nähert sich mit steigender Zahl dem tatsächlichen Mittelwert. Das ist die wirksamste Maßnahme gegen die typische J-Kurve von Bewertungsportalen, bei der Extremmeinungen überrepräsentiert sind und mittlere Erfahrungen fehlen.

**Sichtbarkeitsregeln**

| Element | Ab wann sichtbar |
|---|---|
| Einzelbewertung inklusive Freitexte | sofort nach Moderation |
| Aggregierter Betriebsscore | ab drei Bewertungen |
| Subscores | ab drei Bewertungen |
| Zahlenangaben wie Vergütung oder Überstunden | nur aggregiert, ab fünf Bewertungen, in Spannen |
| Lehrjahr, Beruf, Zeitraum in der Einzelansicht | Beruf und Jahr ja, Lehrjahr und Monat nein |

**Alterung.** Bewertungen älter als drei Jahre bekommen geringeres Gewicht und eine sichtbare Kennzeichnung. Ausbildungsqualität hängt oft an einzelnen Personen und ändert sich mit deren Wechsel.

**Einladungslogik.** Spontane Bewertungen fallen systematisch extremer aus als angeforderte; eine schlichte Einladung reduziert die Extremität nachweislich. Deshalb drei feste Anlässe für eine aktive Einladung: nach der Probezeit, jährlich zum Ausbildungsbeginn, und drei Monate nach Ende der Ausbildung. Wer über eine Einladung kommt, wird intern markiert, weil diese Stichprobe repräsentativer ist.

---

## 9. Qualitätsfilter im Hintergrund

Kein sichtbarer Aufwand für den Azubi, alles serverseitig.

- Bearbeitungszeit pro Bildschirm, Markierung bei Unterschreiten einer Mindestzeit
- Straightlining-Index über die Dimensionsfragen, funktioniert nur dank der gemischten Polung
- Konsistenzpaar K4 gegen die Ausbilder-Modulfrage zur Erreichbarkeit
- Abgleich Gesamturteil gegen Detailwert, bereits in A2 sichtbar behandelt
- Unmögliche Kombinationen, etwa null Überstunden bei gleichzeitig maximaler Belastung durch Mehrarbeit
- Geräte- und Zeitmuster gegen mehrfache Bewertungen desselben Betriebs
- Textprüfung auf Namen, Beleidigungen und harte Tatsachenbehauptungen vor der Veröffentlichung

Verdächtige Bewertungen werden nicht automatisch gelöscht, sondern in die manuelle Moderation gegeben. Automatisches Löschen trifft erfahrungsgemäß vor allem sehr ausführliche, ehrliche Bewertungen.

---

## 10. Der wunde Punkt: Kleinbetriebe

Bei "nur ich" oder "2 bis 5 Azubis" in S6 weiß der Chef sofort, wer geschrieben hat. Eine Einzelbewertung, die anklickbar im Profil steht, ist dann faktisch nicht anonym. Das betrifft im Handwerk die Mehrheit der Betriebe.

Drei Möglichkeiten, jeweils mit Preis:

1. **Ehrlicher Hinweis plus Wahlmöglichkeit.** Vor dem Absenden: "In einem Betrieb mit einem Azubi kann dein Chef wahrscheinlich erkennen, dass du das geschrieben hast." Dazu die Option, die Bewertung erst nach Ende der Ausbildung zu veröffentlichen. Kostet Bewertungen, schützt Nutzer, wirkt vertrauensbildend.
2. **Verzögerte Veröffentlichung als Standard** bei S6 = "nur ich", etwa sechs Monate. Schützt automatisch, verzerrt aber die Aktualität.
3. **Nur Score, keine Einzelansicht** unterhalb einer Mindestzahl. Widerspricht deinem Wunsch nach klickbaren Einzelbewertungen, wäre aber die sicherste Variante.

Empfehlung: Variante 1 als Grundeinstellung, Variante 2 als angebotene Alternative im selben Dialog.

---

## 11. Was noch offen ist

- Vergütung abfragen oder nicht? Die Angabe ist der stärkste Vergleichsanreiz für Nutzer und gleichzeitig die Angabe, die Betriebe am ehesten zur Löschungsforderung bringt.
- Sollen Betriebe auf Bewertungen antworten dürfen? Das verändert das Antwortverhalten der Azubis spürbar, weil sie mit einer Reaktion rechnen.
- Wie hältst du es mit Bewertungen aus Betrieben, die dafür werben? Eine Einladung durch den Ausbilder selbst hebt die Scores systematisch.
- Brauchst du die Filterlogik als Entscheidungsbaum in Pseudocode für die Flutter-Umsetzung, oder reicht diese Tabellenform?
