/** Game rules, scoring weights, branding, and submission settings. */
export const GAME_CONFIG = {
  title: '2026 World Cup Pool',
  subtitle: 'IMW Industries · EEC activity',
  tagline: 'Driven by knowledge, fueled by Experience',
  organization: 'IMW Industries',
  website: 'https://www.imw.ca',

  /** Current app phase — knockout UI unlocks after group stage. */
  phase: 'groupStage',

  adminPin: '22002266',

  /**
   * SharePoint submission endpoint.
   * Paste your Power Automate HTTP trigger URL after following docs/sharepoint-setup.md.
   * The flow writes each submission to a SharePoint List (no local file needed).
   */
  sharepoint: {
    enabled: true,
    webhookUrl:
      'https://31bd6c594580eb2ba958b5aa89e7c7.55.environment.api.powerplatform.com:443/powerautomate/automations/direct/workflows/1ad7f394edf9464b876c0c2f309ec7c7/triggers/manual/paths/invoke?api-version=1',
    /** Paste URL for the "Get leaderboard" Power Automate flow after Step 4 in docs/sharepoint-setup.md. Leave blank until the list branch is configured — do not use the submit URL here before that. */
    leaderboardFetchUrl: '',
    listName: 'World Cup 2026 Entries',
  },

  scoring: {
    group: {
      perPosition: 1,
      winnerBonus: 1,
    },
    knockout: {
      r32: 1,
      r16: 2,
      qf: 4,
      sf: 8,
      final: 16,
    },
  },

  windows: {
    groupStage: {
      id: 'groupStage',
      label: 'Group stage picks',
      start: '2026-06-01',
      end: '2026-06-10',
      description: 'Rank all 12 groups (1st through 4th place).',
    },
    knockoutEarly: {
      id: 'knockoutEarly',
      label: 'First 3 knockout games',
      start: '2026-06-25',
      end: '2026-06-26',
      description:
        'Opens after group stage — pick winners for the first three Round of 32 matches.',
    },
    knockoutRest: {
      id: 'knockoutRest',
      label: 'Remaining knockout picks',
      start: '2026-06-29',
      end: '2026-07-18',
      description:
        'Pick all remaining knockout winners and predict the Final score (tiebreaker).',
    },
  },

  finalDate: '2026-07-19',
};

export const ROUND_LABELS = {
  r32: 'Round of 32',
  r16: 'Round of 16',
  qf: 'Quarter-finals',
  sf: 'Semi-finals',
  final: 'Final',
};

export const ROUND_POINTS = GAME_CONFIG.scoring.knockout;

export function getMaxGroupPoints() {
  return (
    12 *
    (4 * GAME_CONFIG.scoring.group.perPosition +
      GAME_CONFIG.scoring.group.winnerBonus)
  );
}
