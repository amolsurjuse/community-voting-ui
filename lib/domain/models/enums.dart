enum EventVisibility {
  public('Public',
      'Searchable and discoverable. Anyone who meets the verification requirement can vote.'),
  unlisted('Unlisted',
      'Hidden from search. Anyone with the link or QR code who meets the verification requirement can vote.'),
  private('Private',
      'Access only through invitation, access code, or organizer approval.');

  const EventVisibility(this.label, this.explanation);
  final String label;
  final String explanation;
}

enum BallotType {
  singleChoice('Single choice', 'Pick exactly one option.'),
  multipleChoice('Multiple choice', 'Pick several options within a set range.'),
  rankedChoice('Ranked choice', 'Order options by preference.'),
  score('Score voting', 'Rate each option. Coming soon.');

  const BallotType(this.label, this.explanation);
  final String label;
  final String explanation;
}

enum VerificationLevel {
  basicInstall(
    'Basic installation',
    'One ballot per app installation for this event.',
    'One ballot is allowed per verified app installation for this event. '
        'This does not guarantee one ballot per individual person.',
  ),
  verifiedInstall(
    'Verified installation',
    'One ballot per attested app installation.',
    'This event uses device attestation. One ballot is allowed per verified '
        'app installation. This does not guarantee one ballot per individual person.',
  ),
  phone(
    'Phone verification',
    'One ballot per verified phone number.',
    'You will confirm a one-time code sent to your phone. Your number is used '
        'only to prevent duplicate ballots and is never shown to the organizer.',
  ),
  invitation(
    'Invitation',
    'One ballot per invitation.',
    'Voting requires a valid invitation link or access code from the organizer.',
  ),
  organizerApproval(
    'Organizer approval',
    'The organizer approves each participant.',
    'The organizer reviews and approves each enrollment before a ballot can be cast.',
  );

  const VerificationLevel(this.label, this.summary, this.detail);
  final String label;
  final String summary;
  final String detail;
}

enum ResultVisibility {
  live('Live results', 'Results update publicly while voting is open.'),
  afterVote(
      'After you vote', 'Results are visible once your ballot is accepted.'),
  afterClose('After event closes', 'Results are published when voting ends.'),
  organizerOnly('Organizer only', 'Only the organizer can see results.');

  const ResultVisibility(this.label, this.explanation);
  final String label;
  final String explanation;
}

enum EventStatus { draft, scheduled, open, closed, archived }

enum EventCategory {
  community('Community'),
  awards('Awards'),
  workplace('Workplace'),
  club('Club'),
  school('School'),
  product('Product'),
  other('Other');

  const EventCategory(this.label);
  final String label;
}
