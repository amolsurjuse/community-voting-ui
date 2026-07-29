import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsevote/data/providers.dart';
import 'package:pulsevote/features/create/create_wizard_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  CreateWizardController controller() =>
      container.read(createWizardProvider('').notifier);
  WizardState state() => container.read(createWizardProvider(''));

  group('Event creation wizard', () {
    test('new draft starts at basics with sensible defaults', () {
      final s = state();
      expect(s.step, WizardStep.basics);
      expect(s.draft.isDraft, isTrue);
      expect(s.draft.endsAt, isNotNull); // default deadline, not indefinite
      expect(s.readyToPublish, isFalse);
    });

    test('candidate add, duplicate, remove and reorder', () {
      final c = controller();
      c.addCandidate(name: 'Alpha');
      c.addCandidate(name: 'Beta');
      c.addCandidate(name: 'Gamma');
      expect(state().draft.activeCandidates.map((x) => x.name).toList(),
          ['Alpha', 'Beta', 'Gamma']);

      c.reorderCandidates(0, 3); // Alpha to the end
      expect(state().draft.activeCandidates.map((x) => x.name).toList(),
          ['Beta', 'Gamma', 'Alpha']);

      c.duplicateCandidate(state().draft.activeCandidates.first.id);
      expect(state().draft.activeCandidates.length, 4);

      final removeId = state().draft.activeCandidates.last.id;
      c.removeCandidate(removeId);
      expect(state().draft.activeCandidates.length, 3);
    });

    test('draft persists through the repository', () async {
      final c = controller();
      c.updateDraft(state().draft.copyWith(title: 'Persisted event'));
      c.addCandidate(name: 'One');
      c.addCandidate(name: 'Two');
      final saved = await c.saveDraft();
      expect(saved, isTrue);

      final backend = container.read(mockBackendProvider);
      final stored = backend.events[state().draft.id];
      expect(stored, isNotNull);
      expect(stored!.title, 'Persisted event');
      expect(stored.candidates.length, 2);
    });

    test('publish requires title and at least two candidates', () async {
      final c = controller();
      expect(await c.publish(), isFalse);

      c.updateDraft(state().draft.copyWith(title: 'Valid title'));
      c.addCandidate(name: 'One');
      c.addCandidate(name: 'Two');
      expect(state().readyToPublish, isTrue);
      expect(await c.publish(), isTrue);
      expect(state().status, WizardStatus.published);
      expect(state().draft.isOpen, isTrue);
    });
  });
}
