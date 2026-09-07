/// What kind of work a quotation is pricing.
///
/// Design and construction are priced against different promises, so a bid for
/// one carries terms that are meaningless — and misleading — on the other. The
/// provider web app already draws this line when it decides which editor to
/// show (`features/projects/quotation-variant.ts`); this is the owner side of
/// the same rule, so the two apps agree on what a quotation means.
///
/// The concrete case: `freeRevisionCount` and `extraRevisionFee` are read by
/// the server only on the design path — `DesignService.RequestRevisionAsync`
/// counts revision rounds, refuses the one that exceeds the free quota and
/// opens an `extra_revision` change order for the fee. A construction-only
/// engagement has no `Design` rows at all, so nothing ever consults them.
/// Showing them anyway puts a revision quota and a per-round fee in front of
/// the owner, on the document the contract is built from, that no code will
/// ever honour.
enum QuotationScope {
  design,
  construction,

  /// The caller could not say. Everything is shown — see [showsDesignTerms].
  unknown,
}

/// Reads the server's scope vocabulary.
///
/// The backend spells this two different ways depending on how the quotation
/// was anchored — `ProjectPost.serviceKind` for a bid attached to an
/// application, `ProjectWorking.contractType` for a direct invitation — but
/// both serialise the same three values, so one parser covers both.
///
/// `both` resolves to [QuotationScope.design] deliberately: a turnkey
/// engagement does carry a design phase, the revision quota applies to it, and
/// the server will enforce it. Treating `both` as construction would hide
/// terms that are genuinely binding.
QuotationScope quotationScopeFrom(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'construction':
      return QuotationScope.construction;
    case 'design':
    case 'both':
      return QuotationScope.design;
    default:
      return QuotationScope.unknown;
  }
}

extension QuotationScopeView on QuotationScope {
  /// Whether the design-only revision terms belong on screen.
  ///
  /// [QuotationScope.unknown] fails **open**. Hiding a term the provider
  /// actually published is the worse error of the two: the owner would be
  /// deciding on a document with a clause missing, and would have no way to
  /// know it. Showing an irrelevant block is only noise, and it only happens
  /// when the caller could not name the scope.
  bool get showsDesignTerms => this != QuotationScope.construction;

  /// Whether construction-only terms belong on screen.
  ///
  /// Nothing is gated behind this yet — the owner's quotation screen has no
  /// construction-only section today, so the leak this file fixes runs in one
  /// direction only. It exists so the next construction-specific field has an
  /// obvious home and does not get rendered unconditionally the way the
  /// revision block was.
  bool get showsConstructionTerms => this != QuotationScope.design;

  /// Names the document, so the owner can see which set of terms they are
  /// reading rather than inferring it from which sections happen to appear.
  /// Null when the scope is unknown — a guessed label would be worse than none.
  String? get label => switch (this) {
        QuotationScope.design => 'Design quotation',
        QuotationScope.construction => 'Construction quotation',
        QuotationScope.unknown => null,
      };
}
