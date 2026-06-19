import { useState } from 'react'
import {
  Flame, Grid2x2, Leaf, Wind, ChevronRight, Lock, Trophy, RotateCw,
  CircleDashed, Check, Sparkles, LayoutGrid, Infinity as Inf,
} from 'lucide-react'
import { intensities, games, breathingStyles } from './data'
import { GlyphCircle, GradientButton, OutlineButton, SectionDivider } from './ui'
import Breathing from './Breathing'
import GamePlaceholder from './GamePlaceholder'

const ICON = { flame: Flame, pattern: Grid2x2, leaf: Leaf, slice: Flame }

export default function CurrentFlow() {
  const [step, setStep] = useState({ name: 'intensity' })

  function selectIntensity(it) {
    const game = games.find((g) => g.id === it.game)
    const level = it.id === 'extreme' ? game.unlocked : 1
    setStep({ name: 'playing', intensity: it, game, level })
  }

  function finishGame(score) {
    setStep((s) => ({ name: 'post', intensity: s.intensity, game: s.game, level: s.level, score }))
  }

  switch (step.name) {
    case 'intensity':
      return <IntensitySelect onSelect={selectIntensity} onBreathe={() => setStep({ name: 'breathingPicker' })} />
    case 'playing':
      return (
        <GamePlaceholder
          title={step.game.title}
          level={step.level}
          gradient={step.intensity.grad}
          onComplete={finishGame}
          onQuit={() => finishGame(0)}
        />
      )
    case 'post':
      return (
        <PostGame
          step={step}
          onRestart={() => setStep((s) => ({ name: 'playing', intensity: s.intensity, game: s.game, level: s.level }))}
          onPickLevel={(lvl) => setStep((s) => ({ name: 'playing', intensity: s.intensity, game: s.game, level: lvl }))}
          onTryAnother={() => setStep({ name: 'intensity' })}
          onBreathe={() => setStep({ name: 'breathingPicker' })}
        />
      )
    case 'breathingPicker':
      return <BreathingPicker onPick={(st) => setStep({ name: 'breathing', style: st })} />
    case 'breathing':
      return <Breathing styleId={step.style} variant="current" onDone={() => setStep({ name: 'breathingPicker' })} />
    default:
      return null
  }
}

// ---------- Step 1: intensity select (faithful) ----------
function IntensitySelect({ onSelect, onBreathe }) {
  return (
    <div className="fade-in" style={{ padding: '20px 25px 40px' }}>
      <div className="h3">How strong is the craving?</div>
      <div className="small dim" style={{ marginTop: 6, marginBottom: 28 }}>
        Tap one. There's no wrong answer.
      </div>

      <div className="stack" style={{ gap: 14 }}>
        {intensities.map((it) => {
          const Icon = ICON[it.icon]
          return (
            <button key={it.id} className="tap" onClick={() => onSelect(it)}>
              <div className="card row on-gradient" style={{ background: it.grad }}>
                <GlyphCircle icon={Icon} gradient={it.grad} />
                <div className="grow">
                  <div className="small">{it.title}</div>
                  <div className="tiny dim75">{it.subtitle}</div>
                </div>
                <ChevronRight size={14} className="chev" />
              </div>
            </button>
          )
        })}
      </div>

      <div style={{ margin: '28px 0 14px' }}>
        <SectionDivider text="Or, just slow down" />
      </div>

      <button className="tap" onClick={onBreathe}>
        <div className="card row on-gradient" style={{ background: 'var(--g-meditation)' }}>
          <GlyphCircle icon={Wind} gradient="var(--g-meditation)" />
          <div className="grow">
            <div className="small">Just breathe</div>
            <div className="tiny dim75">No game — slow it down</div>
          </div>
          <ChevronRight size={14} className="chev" />
        </div>
      </button>
    </div>
  )
}

// ---------- Post-game (faithful: best row, rating, still-craving, level grid, actions) ----------
function PostGame({ step, onRestart, onPickLevel, onTryAnother, onBreathe }) {
  const [rating, setRating] = useState(0)
  const headline = {
    extreme: 'You made it through 🔥',
    moderate: 'Worked through it 💪',
    little: 'Caught it early 🌳',
  }[step.intensity.id]
  const support = {
    extreme: "You own what happens next. Cravings don't get a vote.",
    moderate: 'The craving lost some bandwidth. That’s the win.',
    little: "That's how it gets easier — every rep counts.",
  }[step.intensity.id]

  return (
    <div className="fade-in" style={{ padding: '20px 25px 40px' }}>
      <div
        className="medallion"
        style={{ background: step.intensity.grad, width: 60, height: 60, marginBottom: 16 }}
      >
        <Check size={26} strokeWidth={3} color="#fff" />
      </div>
      <div className="h2">{headline}</div>
      <div className="small dim" style={{ marginTop: 6, marginBottom: 22 }}>
        {support}
      </div>

      {/* best row */}
      <div
        className="row"
        style={{
          background: 'var(--c-button)',
          border: '1px solid var(--c-gray)',
          borderRadius: 14,
          padding: '12px 16px',
          marginBottom: 22,
        }}
      >
        <Trophy size={16} color="#5BB4A9" />
        <span className="tiny dim">This session</span>
        <span className="small">{step.score}</span>
        <div className="grow" />
        <span className="tiny dim">Best</span>
        <span className="small" style={{ color: '#5BB4A9' }}>
          {Math.max(step.score, 14)}
        </span>
      </div>

      {/* rating card (feedback monster) */}
      <div
        className="card card-plain"
        style={{ border: '1.5px solid rgba(91,180,169,0.5)', marginBottom: 22 }}
      >
        <div className="row">
          <div style={{ fontSize: 48, flexShrink: 0 }}>{rating ? '😋' : '👾'}</div>
          <div className="grow">
            <div
              className="small"
              style={{
                background: 'var(--c-bg)',
                border: '1px solid var(--c-gray)',
                borderRadius: 12,
                padding: '6px 12px',
                display: 'inline-block',
                marginBottom: 8,
              }}
            >
              {rating ? 'Yum! Thanks 💛' : 'I LOVE feedback!'}
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              {[1, 2, 3, 4, 5].map((v) => (
                <button key={v} className="tap" style={{ width: 'auto' }} onClick={() => setRating(v)}>
                  <span style={{ fontSize: 24, color: v <= rating ? '#5BB4A9' : 'rgba(28,28,30,0.25)' }}>★</span>
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* still craving */}
      <div className="tiny dim" style={{ marginBottom: 8 }}>
        Still craving?
      </div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 22 }}>
        <StillBtn icon={RotateCw} text="Yes" filled grad={step.intensity.grad} onClick={onRestart} />
        <StillBtn icon={CircleDashed} text="A little" onClick={() => {}} />
        <StillBtn icon={Check} text="No" onClick={onTryAnother} />
      </div>

      {/* level grid */}
      <div className="row" style={{ marginBottom: 8 }}>
        <span className="tiny dim grow">{step.game.title} levels</span>
        <span className="tiny dim">
          Unlocked: {step.game.unlocked} / {step.game.levels}
        </span>
      </div>
      <div className="level-grid" style={{ marginBottom: 24 }}>
        {Array.from({ length: step.game.levels }, (_, i) => i + 1).map((lvl) => {
          const unlocked = lvl <= step.game.unlocked
          const current = lvl === step.level
          return (
            <button
              key={lvl}
              className={`level-cell${unlocked ? '' : ' locked'}${current ? ' current' : ''}`}
              style={current ? { background: step.intensity.grad } : undefined}
              onClick={() => unlocked && onPickLevel(lvl)}
            >
              {unlocked ? lvl : <Lock size={15} style={{ opacity: 0.6 }} />}
            </button>
          )
        })}
        <button
          className="level-cell current"
          style={{ background: 'var(--g-clear30)' }}
          onClick={() => onPickLevel(step.level)}
        >
          <Inf size={18} color="#fff" />
        </button>
      </div>

      {/* actions */}
      <div className="stack" style={{ gap: 14 }}>
        <GradientButton icon={LayoutGrid} gradient="var(--g-claire)" text="Try a different game" onClick={onTryAnother} />
        <div style={{ display: 'flex', gap: 14 }}>
          <div style={{ flex: 1 }}>
            <OutlineButton icon={Wind} iconGradient="var(--g-meditation)" text="Breathe" onClick={onBreathe} />
          </div>
          <div style={{ flex: 1 }}>
            <OutlineButton icon={Sparkles} iconGradient="var(--g-claire)" text="Claire" onClick={() => {}} />
          </div>
        </div>
        <OutlineButton icon={Check} iconGradient="var(--g-clear30)" text="I'm done" onClick={onTryAnother} />
      </div>
    </div>
  )
}

function StillBtn({ icon: Icon, text, filled, grad, onClick }) {
  return (
    <button className="tap" onClick={onClick} style={{ flex: 1 }}>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 6,
          padding: '14px 4px',
          borderRadius: 14,
          background: filled ? grad : 'var(--c-button)',
          color: filled ? '#fff' : 'var(--c-text)',
          border: filled ? 'none' : '1px solid var(--c-gray)',
        }}
      >
        <Icon size={15} />
        <span className="small">{text}</span>
      </div>
    </button>
  )
}

// ---------- Breathing style picker (faithful gradient cards) ----------
function BreathingPicker({ onPick }) {
  return (
    <div className="fade-in" style={{ padding: '20px 25px 40px', minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <div className="h2">Nice and slow 🌿</div>
      <div className="small dim" style={{ marginTop: 6 }}>
        Pick a style — circle or rolling hill.
      </div>
      <div style={{ flex: 1 }} />
      <div className="stack" style={{ gap: 14 }}>
        {breathingStyles.map((st) => (
          <GradientButton
            key={st.id}
            icon={st.id === 'circle' ? CircleDashed : Wind}
            gradient="var(--g-meditation)"
            text={st.title}
            onClick={() => onPick(st.id)}
          />
        ))}
        <OutlineButton icon={Check} iconGradient="var(--g-clear30)" text="I'm good" onClick={() => {}} />
      </div>
    </div>
  )
}
