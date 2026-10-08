import 'package:ai_explorer/curriculum/episode_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('worldOf resolves by prefix; unknown or malformed ids resolve to null',
      () {
    expect(EpisodeCatalog.worldOf('pf_ep01')?.id, 'pattern_forest');
    expect(EpisodeCatalog.worldOf('ml_ep07')?.id, 'music_lab');
    expect(EpisodeCatalog.worldOf('zz_ep01'), isNull);
    expect(EpisodeCatalog.worldOf('pf_01'), isNull);
    expect(EpisodeCatalog.worldOf('pf_ep1'), isNull);
  });

  test('next walks a world in order and stops at its end', () {
    expect(EpisodeCatalog.next('pf_ep01')?.id, 'pf_ep02');
    expect(EpisodeCatalog.next('pf_ep02'), isNull);
    expect(EpisodeCatalog.next('unknown'), isNull);
  });

  test('canPlay: free always, premium only with entitlement', () {
    const free = CatalogEpisode('pf_ep90');
    const paid = CatalogEpisode('pf_ep91', premium: true);
    expect(EpisodeCatalog.canPlay(free, isPremium: false), isTrue);
    expect(EpisodeCatalog.canPlay(paid, isPremium: false), isFalse);
    expect(EpisodeCatalog.canPlay(paid, isPremium: true), isTrue);
  });

  test('resume picks the first unfinished episode, then restarts', () {
    final pf = EpisodeCatalog.world('pattern_forest')!;
    String? r(Set<String> done) =>
        EpisodeCatalog.resume(pf, done, isPremium: false);
    expect(r({}), 'pf_ep01');
    expect(r({'pf_ep01'}), 'pf_ep02');
    expect(r({'pf_ep01', 'pf_ep02'}), 'pf_ep01');
    final ml = EpisodeCatalog.world('music_lab')!;
    expect(EpisodeCatalog.resume(ml, {}, isPremium: false), isNull,
        reason: 'free users cannot start a premium-only world');
    expect(EpisodeCatalog.resume(ml, {}, isPremium: true), 'ml_ep01');
    expect(
        EpisodeCatalog.resume(EpisodeCatalog.world('gadget_city')!, {},
            isPremium: true),
        isNull);
  });

  const mixed = CatalogWorld(
    id: 'test_world', prefix: 'tw', emoji: '🧪', color: 0, episodes: [
      CatalogEpisode('tw_ep01'),
      CatalogEpisode('tw_ep02', premium: true),
      CatalogEpisode('tw_ep03'),
    ]);

  test('resume skips premium episodes for free users', () {
    expect(EpisodeCatalog.resume(mixed, {'tw_ep01'}, isPremium: false),
        'tw_ep03');
    expect(EpisodeCatalog.resume(mixed, {'tw_ep01'}, isPremium: true),
        'tw_ep02');
  });

  test('shipped catalog: Pattern Forest free, Music Lab premium, Gadget City empty',
      () {
    WorldAccess a(String id, bool p) =>
        EpisodeCatalog.access(EpisodeCatalog.world(id)!, isPremium: p);
    expect(a('pattern_forest', false), WorldAccess.open);
    expect(a('music_lab', false), WorldAccess.locked);
    expect(a('music_lab', true), WorldAccess.open);
    expect(a('gadget_city', true), WorldAccess.comingSoon);
    expect(EpisodeCatalog.episode('ml_ep01')!.premium, isTrue);
    expect(EpisodeCatalog.episode('pf_ep01')!.premium, isFalse);
  });

  test('access: open, locked when all premium, coming soon when empty', () {
    const allPaid = CatalogWorld(
        id: 'p', prefix: 'pp', emoji: '', color: 0,
        episodes: [CatalogEpisode('pp_ep01', premium: true)]);
    const empty =
        CatalogWorld(id: 'e', prefix: 'ee', emoji: '', color: 0, episodes: []);
    expect(EpisodeCatalog.access(mixed, isPremium: false), WorldAccess.open);
    expect(EpisodeCatalog.access(allPaid, isPremium: false), WorldAccess.locked);
    expect(EpisodeCatalog.access(allPaid, isPremium: true), WorldAccess.open);
    expect(EpisodeCatalog.access(empty, isPremium: true), WorldAccess.comingSoon);
  });
}
