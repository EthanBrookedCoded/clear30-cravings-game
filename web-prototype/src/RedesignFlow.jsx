import { useState, useEffect, useRef } from 'react'
import {
  Wind, Play, Pause, ChevronLeft, Headphones, Gamepad2,
  MoveHorizontal, Grid2x2, Scissors, Check, Clock, Sparkles, Lock,
} from 'lucide-react'
import { meditations, games, cadences } from './data'
import { tintFor } from './ui'
import Breathing from './Breathing'
import GamePlaceholder from './GamePlaceholder'

const GAME_ICON = { push: MoveHorizontal, pattern: Grid2x2, slice: Scissors }

export default function RedesignFlow() {
  const [step, setStep] = useState({ name: 'hub' })
  const back = () => setStep({ name: 'hub' })

  // In the real app each of these would open as its OWN sheet stacked on top of the
  // cravings sheet (a meditation tap opens a player sheet; a breathwork tap opens a
  // breathing sheet). Here we swap the screen in place — the back buttons stand in for
  // "dismiss the stacked sheet."
  const playGame = (game, level) => setStep({ name: 'gamePlaying', game, level })

  switch (step.name) {
    case 'hub':
      return (
        <Hub
          onPlayMed={(m) => setStep({ name: 'medPlayer', med: m })}
          onBreathe={(cadenceId) => setStep({ name: 'breathing', cadenceId: cadenceId || 'calm' })}
          onGame={(g) => playGame(g, g.unlocked)}
        />
      )
    case 'medPlayer':
      return <MedPlayer med={step.med} onBack={back} />
    case 'breathing':
      return (
        <Breathing
          styleId="hill"
          cadenceId={step.cadenceId}
          variant="redesign"
          onDone={back}
          onBack={back}
        />
      )
    case 'gamePlaying':
      return (
        <GamePlaceholder
          title={step.game.title}
          level={step.level}
          gradient={step.game.grad}
          onComplete={(score) => setStep({ name: 'gamePost', game: step.game, level: step.level, score })}
          onQuit={back}
        />
      )
    case 'gamePost':
      return (
        <GamePost
          game={step.game}
          level={step.level}
          score={step.score}
          onPlayLevel={(lvl) => playGame(step.game, lvl)}
          onDone={back}
        />
      )
    default:
      return null
  }
}

// ---------- Category hub ----------
function Hub({ onPlayMed, onBreathe, onGame }) {
  return (
    <div className="fade-in" style={{ padding: '18px 0 40px' }}>
      <div style={{ padding: '0 25px' }}>
        <div className="h2">Cravings</div>
        <div className="small dim" style={{ marginTop: 6 }}>
          This will pass. Pick what helps right now.
        </div>
      </div>

      {/* ---- Meditations: an audio rail (content-forward, not a button) ---- */}
      <div style={{ marginTop: 30 }}>
        <div className="row" style={{ padding: '0 25px' }}>
          <Headphones size={18} color="#5B9CF0" />
          <span className="small grow" style={{ fontWeight: 500 }}>
            Meditations
          </span>
        </div>
        <div
          style={{ display: 'flex', gap: 12, overflowX: 'auto', padding: '14px 25px 4px' }}
        >
          {meditations.map((m) => (
            <button
              key={m.id}
              className="tap"
              style={{ width: 'auto', flexShrink: 0 }}
              onClick={() => onPlayMed(m)}
            >
              <div style={{ width: 144 }}>
                <div
                  style={{
                    height: 144,
                    borderRadius: 18,
                    background: m.grad,
                    display: 'grid',
                    placeItems: 'center',
                    color: '#fff',
                    boxShadow: '0 8px 20px rgba(0,0,0,0.18)',
                    position: 'relative',
                  }}
                >
                  <Play size={30} fill="#fff" />
                  <span
                    className="mini"
                    style={{
                      position: 'absolute',
                      bottom: 8,
                      right: 10,
                      background: 'rgba(0,0,0,0.25)',
                      padding: '2px 7px',
                      borderRadius: 8,
                    }}
                  >
                    {m.length}
                  </span>
                </div>
                <div className="small" style={{ marginTop: 8, fontWeight: 500 }}>
                  {m.title}
                </div>
                <div className="tiny dim">{m.teacher}</div>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* ---- Breathwork: a soft feature panel (distinct treatment) ----
           Tapping the panel opens breathwork with the default cadence; tapping a specific
           cadence chip opens it pre-selected to that cadence. In the real app this opens a
           breathwork sheet stacked on top of the cravings sheet. */}
      <div style={{ padding: '26px 25px 0' }}>
        <div
          onClick={() => onBreathe()}
          style={{ cursor: 'pointer' }}
        >
          <div
            style={{
              borderRadius: 22,
              padding: 20,
              background: 'var(--g-meditation)',
              color: '#fff',
              position: 'relative',
              overflow: 'hidden',
              boxShadow: '0 10px 24px rgba(91,156,240,0.3)',
            }}
          >
            {/* concentric breathing motif */}
            <div
              style={{
                position: 'absolute',
                right: -40,
                top: -40,
                width: 160,
                height: 160,
                borderRadius: '50%',
                border: '2px solid rgba(255,255,255,0.35)',
              }}
            />
            <div
              style={{
                position: 'absolute',
                right: -10,
                top: -10,
                width: 100,
                height: 100,
                borderRadius: '50%',
                border: '2px solid rgba(255,255,255,0.5)',
              }}
            />
            <div className="row" style={{ marginBottom: 10 }}>
              <Wind size={20} />
              <span className="small" style={{ fontWeight: 600 }}>
                Breathwork
              </span>
            </div>
            <div className="h3" style={{ maxWidth: 200 }}>
              Slow it down
            </div>
            <div className="tiny dim75" style={{ marginTop: 4 }}>
              Guided breathing · pick your cadence
            </div>
            {/* cadence chips — each opens breathwork pre-selected to that cadence */}
            <div style={{ display: 'flex', gap: 8, marginTop: 14, flexWrap: 'wrap' }}>
              {cadences.map((c) => (
                <button
                  key={c.id}
                  className="mini"
                  onClick={(e) => {
                    e.stopPropagation()
                    onBreathe(c.id)
                  }}
                  style={{
                    fontFamily: 'var(--font)',
                    color: '#fff',
                    cursor: 'pointer',
                    border: '1px solid rgba(255,255,255,0.5)',
                    background: 'rgba(255,255,255,0.12)',
                    borderRadius: 999,
                    padding: '6px 11px',
                  }}
                >
                  {c.title} {c.pattern}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* ---- Games: a playful 2-up tile grid (distinct again) ---- */}
      <div style={{ padding: '26px 25px 0' }}>
        <div className="row" style={{ marginBottom: 14 }}>
          <Gamepad2 size={18} color="#FF8C59" />
          <span className="small grow" style={{ fontWeight: 500 }}>
            Games
          </span>
          <span className="tiny dim">Ride out the urge</span>
        </div>
        <div className="game-grid">
          {games.map((g) => {
            const Icon = GAME_ICON[g.icon]
            return (
              <button key={g.id} className="tap" onClick={() => onGame(g)} style={{ width: 'auto' }}>
                <div className="game-tile" style={{ background: g.grad }}>
                  <div className="tile-icon">
                    <Icon size={20} color="#fff" />
                  </div>
                  <div>
                    <div className="small" style={{ fontWeight: 600 }}>
                      {g.title}
                    </div>
                    <div className="tiny dim75">
                      Lvl {g.unlocked} / {g.levels}
                    </div>
                  </div>
                </div>
              </button>
            )
          })}
          {/* a 4th tile inviting more, keeps the grid balanced */}
          <button className="tap" style={{ width: 'auto' }} onClick={() => onGame(games[0])}>
            <div
              className="game-tile"
              style={{
                background: 'var(--c-button)',
                color: 'var(--c-text)',
                boxShadow: 'none',
                border: '1.5px dashed var(--c-gray)',
                justifyContent: 'center',
                alignItems: 'center',
                textAlign: 'center',
              }}
            >
              <Sparkles size={22} color="#5BB4A9" />
              <div className="tiny dim" style={{ marginTop: 8 }}>
                More coming
              </div>
            </div>
          </button>
        </div>
      </div>
    </div>
  )
}

// ---------- Mock meditation player ----------
function MedPlayer({ med, onBack }) {
  const [playing, setPlaying] = useState(true)
  const [progress, setProgress] = useState(0)

  useEffect(() => {
    if (!playing) return
    const t = setInterval(() => setProgress((p) => (p >= 100 ? 100 : p + 0.6)), 100)
    return () => clearInterval(t)
  }, [playing])

  return (
    <div
      className="fade-in"
      style={{
        position: 'relative',
        height: '100%',
        minHeight: '100%',
        display: 'flex',
        flexDirection: 'column',
        background: 'var(--c-bg)',
        padding: '16px 25px 40px',
      }}
    >
      <button className="tap" style={{ width: 'auto' }} onClick={onBack}>
        <span className="xbtn">
          <ChevronLeft size={18} />
        </span>
      </button>

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 28 }}>
        <div
          style={{
            width: 220,
            height: 220,
            borderRadius: 28,
            background: med.grad,
            display: 'grid',
            placeItems: 'center',
            color: '#fff',
            margin: '0 auto',
            boxShadow: '0 20px 50px rgba(0,0,0,0.22)',
          }}
        >
          <Headphones size={56} />
        </div>
        <div style={{ textAlign: 'center' }}>
          <div className="h3">{med.title}</div>
          <div className="small dim" style={{ marginTop: 4 }}>
            {med.teacher} · {med.length}
          </div>
        </div>

        {/* progress bar */}
        <div>
          <div style={{ height: 5, borderRadius: 3, background: 'var(--c-button)', overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${progress}%`, background: med.grad, transition: 'width 0.1s linear' }} />
          </div>
          <div className="row" style={{ marginTop: 8 }}>
            <span className="tiny dim grow">
              <Clock size={12} style={{ verticalAlign: -2 }} /> playing…
            </span>
            <span className="tiny dim">{med.length}</span>
          </div>
        </div>
      </div>

      <button className="tap" onClick={() => setPlaying((p) => !p)} style={{ display: 'grid', placeItems: 'center' }}>
        <div
          style={{
            width: 72,
            height: 72,
            borderRadius: '50%',
            background: 'var(--g-meditation)',
            display: 'grid',
            placeItems: 'center',
            color: '#fff',
            boxShadow: '0 10px 26px rgba(91,156,240,0.4)',
          }}
        >
          {playing ? <Pause size={28} fill="#fff" /> : <Play size={28} fill="#fff" />}
        </div>
      </button>
    </div>
  )
}

// ---------- Post-game: centered "Level N complete" hero + compact level carousel, actions pinned bottom ----------
function GamePost({ game, level, score, onPlayLevel, onDone }) {
  // Completing this level unlocks the next one.
  const unlocked = Math.min(Math.max(game.unlocked, level + 1), game.levels)
  const nextLevel = level < game.levels ? level + 1 : null
  const tint = tintFor[game.grad] || '#5BB4A9'

  // Completion choreography:
  //  1. land on the just-cleared level (highlighted, no check yet)
  //  2. ~400ms: a checkmark pops onto it
  //  3. ~950ms: the next level fades up from locked and becomes the selected highlight
  const [showCheck, setShowCheck] = useState(false)
  const [revealed, setRevealed] = useState(false)
  const [selected, setSelected] = useState(level)

  const railRef = useRef(null)
  const curRef = useRef(null)
  useEffect(() => {
    const c = railRef.current
    const s = curRef.current
    if (c && s) c.scrollLeft = s.offsetLeft - c.clientWidth / 2 + s.clientWidth / 2

    const t1 = setTimeout(() => setShowCheck(true), 400)
    const t2 = setTimeout(() => {
      setRevealed(true)
      setSelected(nextLevel ?? level)
    }, 950)
    return () => {
      clearTimeout(t1)
      clearTimeout(t2)
    }
  }, [nextLevel, level])

  const primaryLabel =
    nextLevel && selected === nextLevel
      ? 'Next level'
      : selected === level
        ? 'Play again'
        : `Play level ${selected}`

  return (
    <div className="fade-in" style={{ padding: '20px 25px 36px', minHeight: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 1, minHeight: 12 }} />

      {/* hero — centered */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center' }}>
        <div className="medallion" style={{ background: game.grad, width: 64, height: 64, marginBottom: 18 }}>
          <Check size={28} strokeWidth={3} color="#fff" />
        </div>
        <div className="h2">Level {level} complete 🎉</div>
        <div className="small dim" style={{ marginTop: 6 }}>
          {game.title} · scored {score}
        </div>
      </div>

      {/* compact level carousel — current is highlighted, scroll back for earlier levels */}
      <div
        ref={railRef}
        style={{
          display: 'flex',
          gap: 10,
          overflowX: 'auto',
          padding: '24px 25px 6px',
          margin: '0 -25px',
          scrollbarWidth: 'none',
        }}
      >
        {Array.from({ length: game.levels }, (_, i) => i + 1).map((lvl) => {
          const isSelected = lvl === selected
          const isCleared = lvl <= level
          const isNext = lvl === nextLevel
          // The next level stays dim until the reveal; everything past it is locked.
          const isUnlocked = isNext ? revealed : lvl <= unlocked && lvl <= level
          const dimNext = isNext && !revealed
          // The cleared level shows its check as soon as it pops (even while still highlighted);
          // earlier cleared levels carry a static check whenever they aren't the selection.
          const showBadge = lvl === level ? showCheck : isCleared && !isSelected
          return (
            <button
              key={lvl}
              ref={lvl === level ? curRef : null}
              className="tap"
              disabled={!isUnlocked && !dimNext}
              onClick={() => (isUnlocked || dimNext) && setSelected(lvl)}
              style={{ width: 'auto', flexShrink: 0, cursor: isUnlocked ? 'pointer' : 'default' }}
            >
              <div
                style={{
                  position: 'relative',
                  width: 52,
                  height: 52,
                  borderRadius: 15,
                  display: 'grid',
                  placeItems: 'center',
                  fontSize: 17,
                  fontWeight: 600,
                  color: isSelected ? '#fff' : isUnlocked || dimNext ? 'var(--c-text)' : 'var(--c-text-25)',
                  background: isSelected ? game.grad : 'var(--c-button)',
                  border: isSelected ? 'none' : `1px solid ${isCleared ? tint + '55' : 'var(--c-gray)'}`,
                  opacity: dimNext ? 0.35 : isUnlocked || isCleared ? 1 : 0.5,
                  transform: isSelected ? 'scale(1.12)' : 'none',
                  boxShadow: isSelected ? '0 8px 18px var(--c-shadow)' : 'none',
                  transition: 'transform 0.3s cubic-bezier(0.2,1.1,0.3,1), opacity 0.45s ease, background 0.3s ease',
                }}
              >
                {lvl > unlocked && !isNext ? <Lock size={14} style={{ opacity: 0.6 }} /> : lvl}
                {showBadge && (
                  <span
                    className="badge-pop"
                    style={{
                      position: 'absolute',
                      top: -5,
                      right: -5,
                      width: 17,
                      height: 17,
                      borderRadius: '50%',
                      background: tint,
                      display: 'grid',
                      placeItems: 'center',
                    }}
                  >
                    <Check size={11} strokeWidth={3.5} color="#fff" />
                  </span>
                )}
              </div>
            </button>
          )
        })}
      </div>

      <div style={{ flex: 1, minHeight: 16 }} />

      {/* actions pinned to the bottom */}
      <div className="stack" style={{ gap: 12 }}>
        <button className="tap" onClick={() => onPlayLevel(selected)}>
          <div className="gbtn" style={{ background: game.grad, justifyContent: 'center' }}>
            <span className="small" style={{ color: '#fff', fontWeight: 600 }}>
              {primaryLabel}
            </span>
          </div>
        </button>
        <button className="tap" onClick={onDone}>
          <div className="obtn">
            <Check size={17} color="#5BB4A9" />
            <span className="small">I'm all good</span>
          </div>
        </button>
      </div>
    </div>
  )
}

