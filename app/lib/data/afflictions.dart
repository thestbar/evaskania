class Affliction {
  const Affliction({required this.name, required this.startPct, required this.note});
  final String name;
  final int startPct;
  final String note;
}

const List<Affliction> xemAfflictions = [
  Affliction(
    name: 'Ελαφρύ ματάκι από ζήλια',
    startPct: 46,
    note: 'Κάποιος ζήλεψε κάτι μικρό — τα μαλλιά σου, μάλλον.',
  ),
  Affliction(
    name: 'Βαρύ μάτι από σχόλιο',
    startPct: 78,
    note: 'Ένα «τι όμορφο/η» ειπώθηκε χωρίς να χτυπηθεί ξύλο.',
  ),
  Affliction(
    name: 'Ψιλό μάτι από αγάπη',
    startPct: 33,
    note: "Ακόμα κι όσοι σ'αγαπάνε ζηλεύουν λίγο.",
  ),
  Affliction(
    name: 'Μάτι από άγνωστο',
    startPct: 91,
    note: 'Δεν ξέρουμε ποιος, αλλά το ένιωσες.',
  ),
];
