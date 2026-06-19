// Mock content. In the real app meditations come from Supabase (craving_resources)
// and games are the three SwiftUI games. Here they're stand-ins for navigation work.

export const meditations = [
  { id: 'm1', title: 'Ride the Wave', length: '6 min', teacher: 'Dr. Fred', grad: 'var(--g-meditation)' },
  { id: 'm2', title: 'This Will Pass', length: '4 min', teacher: 'Tara', grad: 'var(--g-clear30)' },
  { id: 'm3', title: 'Name the Urge', length: '8 min', teacher: 'Dr. Fred', grad: 'var(--g-claire)' },
  { id: 'm4', title: 'Body Scan for Cravings', length: '11 min', teacher: 'Maya', grad: 'var(--g-meditation)' },
  { id: 'm5', title: 'Urge Surfing', length: '5 min', teacher: 'Tara', grad: 'var(--g-clear30)' },
]

export const games = [
  {
    id: 'push_pull',
    title: 'Push & Pull',
    blurb: 'Catch it early',
    grad: 'var(--g-clear30)',
    icon: 'push',
    levels: 12,
    unlocked: 5,
  },
  {
    id: 'pattern',
    title: 'Pattern',
    blurb: 'Work through it',
    grad: 'var(--g-claire)',
    icon: 'pattern',
    levels: 12,
    unlocked: 3,
  },
  {
    id: 'slice',
    title: 'Slice',
    blurb: 'Push past it',
    grad: 'var(--g-red)',
    icon: 'slice',
    levels: 12,
    unlocked: 8,
  },
]

export const breathingStyles = [
  { id: 'circle', title: 'Calm circle', subtitle: 'Expand and release' },
  { id: 'hill', title: 'Rolling hill', subtitle: 'Roll up and down' },
]

export const cadences = [
  { id: 'calm', title: 'Calm', pattern: '4-4-6', subtitle: 'Gentle wind-down', phases: { inhale: 4, holdIn: 4, exhale: 6, holdOut: 0 } },
  { id: 'relaxing', title: 'Relaxing', pattern: '4-7-8', subtitle: 'Popular sleep pattern', phases: { inhale: 4, holdIn: 7, exhale: 8, holdOut: 0 } },
  { id: 'box', title: 'Box', pattern: '4-4-4-4', subtitle: 'Focus / stress reset', phases: { inhale: 4, holdIn: 4, exhale: 4, holdOut: 4 } },
]

export const breathingRewards = [
  'You found your calm 🌿',
  'Steadier already.',
  'That was a real reset.',
  'Nice and slow — well done.',
]

export const intensities = [
  { id: 'extreme', title: 'Extreme', subtitle: 'Right now — push past it', grad: 'var(--g-red)', icon: 'flame', game: 'slice' },
  { id: 'moderate', title: 'Moderate', subtitle: 'Work through it', grad: 'var(--g-claire)', icon: 'pattern', game: 'pattern' },
  { id: 'little', title: 'A little', subtitle: 'Catch it early', grad: 'var(--g-clear30)', icon: 'leaf', game: 'push_pull' },
]
