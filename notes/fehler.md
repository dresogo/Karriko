folgende fehler müssen behoben werden:

Tipp:
npm run dev
http://localhost:3000

cd karriko_flutter
flutter run -d chrome

~~Die Schlüssel in der Historie. Der Merge ändert daran nichts — Supabase-Service-Role-Key, Datenbank-Passwort und NEXTAUTH_SECRET liegen weiter in Commit 66afa2e eines öffentlichen Repos. Rotieren ist der einzige wirksame Schritt.~~

**Erledigt und sachlich falsch gewesen** (geprüft am 4. August 2026): Die `.env.local` in `66afa2e` enthielt ausschließlich `your_*`-Platzhalter aus einer Vorlage, keine echten Zugangsdaten. Eine Rotation war damit gegenstandslos. Die Datei wurde trotzdem per `git filter-repo` aus der Historie entfernt — als Repo-Hygiene, damit die Frage nicht wieder aufkommt. Der genannte Commit existiert nicht mehr. Details in `status-report-2026-08-02.md`, Abschnitt 7.1.

***ENTFERNT***