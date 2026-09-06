import 'dart:math';

/// One flavor of "evil eye" a Ξεμάτισμα reading can turn up — a name and a
/// one-line note. The severity percentage is rolled separately, per call
/// (see [rollXemAffliction]); these pools only supply the flavor text for
/// whichever range that roll lands in, so XemRemovingScreen/XemResultScreen
/// never need to know about tiers or probabilities at all.
class Affliction {
  const Affliction({required this.name, required this.note});
  final String name;
  final String note;
}

// pct == 0. Nothing was actually found — kept in the same Affliction shape
// as every other tier (rather than a special "clean" case in the UI) so the
// joke lives entirely in the flavor text: "found: nothing" is the bit.
const List<Affliction> _cleanPool = [
  Affliction(
    name: 'Τίποτα το αξιοσημείωτο',
    note: 'Καθαρός/ή σαν ουρανός Αυγούστου. Ούτε ίχνος ζήλιας πουθενά.',
  ),
  Affliction(
    name: 'Ένα κενό βλέμμα',
    note: 'Κάποιος σε κοίταξε, αλλά σκεφτόταν τι θα φάει το μεσημέρι.',
  ),
  Affliction(
    name: 'Απών κακός οφθαλμός',
    note: 'Ψάξαμε παντού. Ούτε ένα ψιλό μάτι. Μάλλον σε συμπαθούν πραγματικά.',
  ),
  Affliction(
    name: 'Καθαρή ατμόσφαιρα',
    note: 'Ρίχνουμε τις σταγόνες από συνήθεια — δεν χρειάζονταν, αλλά έτσι κάνουμε.',
  ),
  Affliction(
    name: 'Μηδέν βασκανία',
    note: 'Η γιαγιά κοίταξε δύο φορές. Τίποτα. Μπορεί να προσέχεις κιόλας τα social media.',
  ),
  Affliction(
    name: 'Ζήλια εκτός λειτουργίας',
    note: 'Ο κόσμος έχει άλλα προβλήματα αυτή τη βδομάδα, όχι εσένα.',
  ),
  Affliction(
    name: 'Ανέγγιχτος/η από το κακό μάτι',
    note: 'Ούτε η πεθερά σου να σε κοιτούσε δεν θα έβρισκε κάτι.',
  ),
  Affliction(
    name: 'Πεντακάθαρος αέρας γύρω σου',
    note: 'Το λάδι έμεινε ήρεμο στο ποτήρι. Καλύτερο σημάδι δεν υπάρχει.',
  ),
];

// 1-25%.
const List<Affliction> _mildPool = [
  Affliction(
    name: 'Ελαφρύ ματάκι από ζήλια',
    note: 'Κάποιος ζήλεψε κάτι μικρό — τα μαλλιά σου, μάλλον.',
  ),
  Affliction(
    name: 'Ψιλό μάτι από αγάπη',
    note: "Ακόμα κι όσοι σ'αγαπάνε ζηλεύουν λίγο.",
  ),
  Affliction(
    name: 'Ένα μισό μάτι από τη θεία',
    note: "Σε καμάρωσε λίγο παραπάνω απ' όσο έπρεπε σε ένα τραπέζι.",
  ),
  Affliction(
    name: 'Ελαφρύ κακό μάτι από selfie',
    note: 'Ανέβασες μια φωτογραφία πολύ ωραία. Κάποιος ζήλεψε τον φωτισμό.',
  ),
  Affliction(
    name: 'Ψύχρα από συνάδελφο',
    note: 'Δεν είναι ακριβώς μάτι, είναι απλά κακία με χαμόγελο.',
  ),
  Affliction(
    name: 'Ένα τσίμπημα ζήλιας στο ζυγό',
    note: 'Κάποιος είδε τον νέο σου καφέ και στεναχωρήθηκε λιγάκι.',
  ),
  Affliction(
    name: 'Ελαφρύ μάτι από γείτονα',
    note: 'Ρώτησε πόσο κόστισε κάτι δικό σου. Αυτό ήταν όλο.',
  ),
  Affliction(
    name: 'Ψιλή βασκανία από like',
    note: "Κάποιος σου έβαλε καρδούλα, αλλά το εννοούσε λιγότερο απ'όσο φαινόταν.",
  ),
  Affliction(
    name: 'Μια σταγόνα ζήλιας από ξάδερφο',
    note: 'Συνέκρινε τη ζωή του με τη δική σου. Έχασε.',
  ),
  Affliction(
    name: 'Ελαφρύ μάτι της τύχης',
    note: 'Απλά σου βγήκε λίγη βασκανία επειδή γελούσες πολύ δυνατά χθες.',
  ),
];

// 26-50%.
const List<Affliction> _moderatePool = [
  Affliction(
    name: 'Βαρύ μάτι από σχόλιο',
    note: 'Ένα «τι όμορφο/η» ειπώθηκε χωρίς να χτυπηθεί ξύλο.',
  ),
  Affliction(
    name: 'Μεσαίο μάτι από κουμπάρα',
    note: 'Σε επαίνεσε μπροστά σε όλους. Το εννοούσε, αλλά ζήλεψε κιόλας.',
  ),
  Affliction(
    name: 'Βασκανία μεσαίου μεγέθους από Instagram',
    note: 'Τριάντα άτομα είδαν τη φωτογραφία σου. Ένα τουλάχιστον δεν άντεξε.',
  ),
  Affliction(
    name: 'Μάτι από παλιό συμμαθητή',
    note: 'Σε είδε να τα πας καλά και θυμήθηκε τα δικά του απωθημένα.',
  ),
  Affliction(
    name: 'Ζήλια εν τη γεννέσει',
    note: 'Κάποιος σε ζήλεψε πριν καν καταλάβει γιατί.',
  ),
  Affliction(
    name: 'Μεσαίο κακό μάτι από το γραφείο',
    note: 'Προαγωγή, αναφορά, ή απλά καλύτερη καρέκλα. Έφτασε.',
  ),
  Affliction(
    name: 'Βασκανία από επιτυχία',
    note: 'Τα πήγες καλά σε κάτι. Ο κόσμος δεν το αντέχει πάντα.',
  ),
  Affliction(
    name: 'Ζηλεμένο βλέμμα για το καινούριο αμάξι',
    note: 'Ο γείτονας το είδε παρκαρισμένο και δεν κοιμήθηκε καλά.',
  ),
  Affliction(
    name: 'Μέτριο μάτι από κουτσομπολιό',
    note: 'Μίλησαν για σένα πίσω από την πλάτη σου· όχι κακό, απλά πολύ.',
  ),
  Affliction(
    name: 'Βαριά ζήλια από γάμο ή βάφτιση',
    note: 'Κάποιος σε είδε να χορεύεις καλά. Ζήλεψε το πάσο σου.',
  ),
];

// 51-75%.
const List<Affliction> _heavyPool = [
  Affliction(
    name: 'Μάτι από άγνωστο',
    note: 'Δεν ξέρουμε ποιος, αλλά το ένιωσες.',
  ),
  Affliction(
    name: 'Βαρύ μάτι από πολλά άτομα μαζί',
    note: 'Δεν ήταν ένας. Ήταν σχεδόν όλο το τραπέζι στο γάμο.',
  ),
  Affliction(
    name: 'Έντονη ζήλια από πρώην',
    note: 'Σε είδε χαρούμενο/η. Δεν το χωνεύει ακόμα.',
  ),
  Affliction(
    name: 'Βαρύ κακό μάτι από επιτυχημένη παρουσίαση',
    note: 'Τους εντυπωσίασες. Έναν τουλάχιστον τον πόνεσε.',
  ),
  Affliction(
    name: 'Έντονο μάτι από τη θεία με τη γλώσσα',
    note: 'Σε παίνεψε τρεις φορές στο ίδιο τραπέζι. Ύποπτο.',
  ),
  Affliction(
    name: 'Βαριά βασκανία από viral βίντεο',
    note: 'Το βίντεό σου το είδαν χιλιάδες. Κάποιοι ζήλεψαν, με το σύνολο.',
  ),
  Affliction(
    name: 'Μάτι από κάποιον που σε συγκρίνει συνέχεια',
    note: 'Ξέρεις ποιος. Δεν χρειάζεται να πούμε όνομα.',
  ),
  Affliction(
    name: 'Έντονη ζήλια οικογενειακή',
    note: 'Στην οικογένεια η ζήλια χτυπάει πιο δυνατά, το ξέρεις.',
  ),
  Affliction(
    name: 'Βαρύ μάτι από επιτυχημένο ραντεβού',
    note: 'Πήγε καλά, πολύ καλά. Κάποιος το πληροφορήθηκε και δεν χάρηκε.',
  ),
  Affliction(
    name: 'Σοβαρή βασκανία από ολόκληρο πάρτι',
    note: 'Ήσουν το κέντρο της βραδιάς. Το κέντρο τραβάει μάτια — όλων των ειδών.',
  ),
];

// 76-100%.
const List<Affliction> _severePool = [
  Affliction(
    name: 'Πλήρες μάτι, όλα τα σύμβολα',
    note: 'Σπάνιο, δυνατό, και τελείως τυχαίο. Καλή τύχη σε όποιον το προκάλεσε.',
  ),
  Affliction(
    name: 'Βαρύτατη βασκανία από ολόκληρη γειτονιά',
    note: 'Δεν ξέρουμε πώς έγινε αυτό, αλλά έγινε.',
  ),
  Affliction(
    name: 'Σχεδόν πλήρες μάτι από επιτυχημένη χρονιά',
    note: 'Ολόκληρη χρονιά καλή, χωρίς παράπονο. Κάτι τέτοιο δεν περνάει απαρατήρητο.',
  ),
  Affliction(
    name: 'Ισχυρότατη ζήλια από τον γάμο σου',
    note: 'Ήσουν η νύφη ή ο γαμπρός της βραδιάς και το ξέρεις.',
  ),
  Affliction(
    name: 'Έντονη βασκανία από viral επιτυχία',
    note: 'Έγινες γνωστός/ή μέσα σε ένα βράδυ. Το ίντερνετ δεν συγχωρεί εύκολα.',
  ),
  Affliction(
    name: 'Σχεδόν πλήρες μάτι από πολλαπλή ζήλια',
    note: 'Τρεις άνθρωποι το ίδιο βράδυ. Χωρίς να το συνεννοηθούν.',
  ),
  Affliction(
    name: 'Δυνατότατο κακό μάτι από κληρονομιά τύχης',
    note: 'Σου βγήκε κάτι καλό στην κλήρωση της ζωής. Το πλήρωσες με μάτι.',
  ),
  Affliction(
    name: 'Σοβαρότατη βασκανία, σπάνιο περιστατικό',
    note: 'Η γιαγιά σήκωσε το φρύδι όταν είδε το επίπεδο.',
  ),
  Affliction(
    name: 'Πολύ βαριά ζήλια από επαγγελματική επιτυχία',
    note: 'Πήρες αυτό που άλλοι περίμεναν χρόνια. Το ένιωσαν.',
  ),
  Affliction(
    name: 'Ακραίο μάτι, οριακά φυσιολογικό',
    note: 'Λίγο ακόμα και θα ήταν κρίσιμο περιστατικό. Καλά που σταματήσαμε εδώ.',
  ),
];

// >100%. The scale was supposed to top out at 100 — this tier is what
// happens when it doesn't. Rare, and deliberately over the top.
const List<Affliction> _criticalPool = [
  Affliction(
    name: 'ΚΡΙΣΙΜΟ ΜΑΤΙ — θρύλος βασκανίας',
    note: 'Η γιαγιά σταμάτησε να μετράει. Το λάδι έκανε κύκλο δύο φορές. Δεν το είχε ξαναδεί αυτό.',
  ),
  Affliction(
    name: 'Υπερβασκανία επιπέδου γάμου-γιορτής-viral',
    note: 'Τρεις πηγές ζήλιας ταυτόχρονα. Σπάσαμε τον μετρητή.',
  ),
  Affliction(
    name: 'Το μάτι που έσπασε την κλίμακα',
    note: 'Το 100% ήταν το ταβάνι. Εσύ πέρασες από πάνω, ήρεμα, σαν να μην συνέβη τίποτα.',
  ),
  Affliction(
    name: 'Θρυλικό κακό μάτι, καταγεγραμμένο στα χρονικά',
    note: 'Η κόρη της γιαγιάς θα το διηγείται στα εγγόνια της.',
  ),
  Affliction(
    name: 'Ματιά που ξεπέρασε κάθε προηγούμενο',
    note: 'Χρειάστηκαν διπλές σταγόνες λάδι. Οι απλές δεν έφταναν.',
  ),
  Affliction(
    name: 'Απόλυτο ρεκόρ βασκανίας',
    note: 'Ακόμα και το ποτήρι φαινόταν εντυπωσιασμένο.',
  ),
  Affliction(
    name: 'Το πιο δυνατό μάτι της εβδομάδας, ίσως του μήνα',
    note: 'Δεν ξέρουμε τι έκανες, αλλά όποιο κι αν ήταν, το άξιζε.',
  ),
  Affliction(
    name: 'Υπερμάτιασμα — σπάνιο, επικό, αξέχαστο',
    note: 'Η γιαγιά έκανε τον σταυρό της τρεις φορές αντί για μία.',
  ),
];

List<Affliction> _poolForPct(int pct) {
  if (pct <= 0) return _cleanPool;
  if (pct <= 25) return _mildPool;
  if (pct <= 50) return _moderatePool;
  if (pct <= 75) return _heavyPool;
  if (pct <= 100) return _severePool;
  return _criticalPool;
}

({int pct, Affliction affliction}) _roll(Random random) {
  final r = random.nextDouble();
  final int pct;
  if (r < 0.05) {
    pct = 0; // ~5%: clean
  } else if (r < 0.10) {
    pct = 101 + random.nextInt(60); // ~5%: critical, 101-160
  } else {
    pct = 1 + random.nextInt(100); // ~90%: normal, 1-100
  }
  final pool = _poolForPct(pct);
  return (pct: pct, affliction: pool[random.nextInt(pool.length)]);
}

/// Rolls a fresh (percentage, flavor) pair for a Ξεμάτισμα reading: ~5%
/// chance of a clean 0%, ~5% chance of a "critical" >100% overflow,
/// otherwise uniform 1-100 — each mapped to a pool of flavor text matching
/// that severity.
///
/// If [avoidName] is given and the first roll lands on that exact
/// affliction again, it's rerolled once — a small nudge against back-to-back
/// repeats reading as "the app is stuck", which a single unlucky small-pool
/// draw otherwise can.
({int pct, Affliction affliction}) rollXemAffliction(Random random, {String? avoidName}) {
  final first = _roll(random);
  if (avoidName == null || first.affliction.name != avoidName) return first;
  return _roll(random);
}
