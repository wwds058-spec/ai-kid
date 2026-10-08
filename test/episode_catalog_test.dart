import 'package:ai_explorer/curriculum/episode_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('next walks a world in order and stops at its end', () {
    expect(EpisodeCatalog.next('pf_ep01'), 'pf_ep02');
    expect(EpisodeCatalog.next('pf_ep02'), isNull);
    expect(EpisodeCatalog.next('unknown'), isNull);
  });

  test('resume picks the first unfinished episode, then restarts', () {
    expect(EpisodeCatalog.resume('pattern_forest', {}), 'pf_ep01');
    expect(EpisodeCatalog.resume('pattern_forest', {'pf_ep01'}), 'pf_ep02');
    expect(EpisodeCatalog.resume('pattern_forest', {'pf_ep01', 'pf_ep02'}),
        'pf_ep01');
    expect(EpisodeCatalog.resume('music_lab', {}), isNull);
  });
}
