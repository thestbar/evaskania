class CoffeeVerdict {
  const CoffeeVerdict({required this.symbols, required this.quote});
  final List<String> symbols;
  final String quote;
}

const List<CoffeeVerdict> coffeeVerdicts = [
  CoffeeVerdict(
    symbols: ['Πουλί', 'Κουκκίδες'],
    quote:
        'Ένα πουλί σου φέρνει νέα πριν την Κυριακή, και οι κουκκίδες από κάτω λένε ότι είναι πληρωμένα νέα, όχι κουτσομπολιό.',
  ),
  CoffeeVerdict(
    symbols: ['Φίδι', 'Σταυρός'],
    quote:
        'Υπάρχει ένα φίδι κοντά στα πράγματά σου· όχι επικίνδυνο, απλώς μιλάει πολύ. Ο σταυρός πίσω του λέει ότι καλά έκανες και δεν το άκουσες.',
  ),
  CoffeeVerdict(
    symbols: ['Άγκυρα'],
    quote:
        "Μια άγκυρα τόσο κοντά στο χερούλι θέλει να μείνεις κάπου λίγο παραπάνω απ' όσο σχεδίαζες.",
  ),
  CoffeeVerdict(
    symbols: ['Γάτα', 'Κλειδί'],
    quote:
        'Η γάτα σημαίνει ότι κάποιος κοντινός κρύβει κάτι μικρό. Το κλειδί λέει ότι θα το βρεις χωρίς να ρωτήσεις.',
  ),
  CoffeeVerdict(
    symbols: ['Δέντρο', 'Καρδιά'],
    quote:
        'Ένα δέντρο με μια καρδιά πιασμένη στα κλαδιά του — καλά, αργά νέα για την οικογένεια, τίποτα που βιάζεται.',
  ),
];
