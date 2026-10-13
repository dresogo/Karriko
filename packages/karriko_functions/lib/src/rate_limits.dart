/// Grenzwerte aus der Projektreferenz, §2.4.
///
/// Hier und nicht im Client: Ein Grenzwert, den der Client prüft, gilt nur für
/// den Client. Wer die Function direkt aufruft, käme sonst daran vorbei.
library;

/// Höchstens so viele Bewertungen je Konto in [reviewWindow].
///
/// Ein Azubi bewertet seinen Ausbildungsbetrieb, vielleicht noch einen
/// früheren. Wer an einem Tag mehr abgibt, bewertet vermutlich nicht aus
/// eigener Erfahrung.
const maxReviewsPerWindow = 3;

/// Das Zeitfenster für [maxReviewsPerWindow]: gleitend, nicht ab Mitternacht.
const reviewWindow = Duration(hours: 24);

/// Ab wann das Fenster für eine Einreichung zum Zeitpunkt [now] zählt.
DateTime reviewWindowStart(DateTime now) => now.toUtc().subtract(reviewWindow);

/// Ob eine weitere Bewertung das Limit überschreiten würde.
///
/// [recentCount] ist die Zahl der Bewertungen im Fenster **vor** dieser
/// Einreichung. Bei drei vorhandenen ist die vierte zu viel.
bool reviewLimitReached(int recentCount) => recentCount >= maxReviewsPerWindow;
