import { useEffect, useRef, useState } from 'react'
import { Wind, Gauge, Check, ChevronLeft } from 'lucide-react'
import { cadences, breathingRewards } from './data'
import { Sheet } from './ui'

const REST = 0.55

const PHASE_LABEL = { inhale: 'Breathe in', holdIn: 'Hold', exhale: 'Breathe out', holdOut: 'Hold' }
const PHASE_ORDER = ['inhale', 'holdIn', 'exhale', 'holdOut']

// variant: 'current' (cadence via gradient-card sheet) | 'redesign' (cadence via chips)
// In the real app this whole screen is presented as its own sheet stacked on top of the
// cravings sheet (same as tapping a meditation), so `onBack` dismisses that sheet.
export default function Breathing({
  styleId = 'hill',
  cadenceId: initialCadence = 'calm',
  variant = 'redesign',
  onDone,
  onBack,
}) {
  const [cadenceId, setCadenceId] = useState(initialCadence)
  const cadence = cadences.find((c) => c.id === cadenceId)

  const [scale, setScale] = useState(REST)
  const [dur, setDur] = useState(cadence.phases.inhale)
  const [label, setLabel] = useState('Breathe in')
  const [round, setRound] = useState(1)
  const [elapsed, setElapsed] = useState(0)
  const [showCadence, setShowCadence] = useState(false)
  const [done, setDone] = useState(false)
  const [reward] = useState(() => breathingRewards[Math.floor(elapsedSeed() * breathingRewards.length)])

  const timer = useRef(null)
  const cancelled = useRef(false)
  const startRef = useRef(Date.now()) // shared clock for the rolling-hill canvas

  useEffect(() => {
    cancelled.current = false
    setRound(1)
    startRef.current = Date.now()
    let phaseIndex = 0
    let firstInhale = true // count a round when each inhale BEGINS (after the first)

    function step() {
      if (cancelled.current) return
      const phase = PHASE_ORDER[phaseIndex]
      const secs = cadence.phases[phase]
      // Skip zero-length phases (e.g. holdOut on Calm/Relaxing). Incrementing the round
      // here rather than in the timeout is what keeps the counter advancing for cadences
      // whose cycle wraps to inhale through a skipped phase.
      if (secs <= 0) {
        phaseIndex = (phaseIndex + 1) % 4
        step()
        return
      }
      if (phase === 'inhale') {
        setScale(1)
        if (firstInhale) firstInhale = false
        else setRound((r) => r + 1)
      }
      if (phase === 'exhale') setScale(REST)
      setLabel(PHASE_LABEL[phase])
      setDur(secs)
      timer.current = setTimeout(() => {
        phaseIndex = (phaseIndex + 1) % 4
        step()
      }, secs * 1000)
    }
    step()

    const tick = setInterval(() => setElapsed((e) => e + 1), 1000)
    return () => {
      cancelled.current = true
      clearTimeout(timer.current)
      clearInterval(tick)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cadenceId])

  function finish() {
    cancelled.current = true
    clearTimeout(timer.current)
    setDone(true)
    setTimeout(() => onDone?.(), 2400)
  }

  const mm = String(Math.floor(elapsed / 60)).padStart(1, '0')
  const ss = String(elapsed % 60).padStart(2, '0')

  return (
    <div className="breathe-wrap">
      {/* ambient glow */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background:
            'radial-gradient(360px 360px at 50% 46%, rgba(91,156,240,0.18), transparent 70%)',
          opacity: scale,
          transition: `opacity ${dur}s ease-in-out`,
          pointerEvents: 'none',
        }}
      />

      {/* top bar — back button mirrors the meditation player's */}
      <div
        className="row"
        style={{ padding: '16px 25px 0', position: 'relative', zIndex: 2 }}
      >
        {onBack && (
          <button className="tap" style={{ width: 'auto' }} onClick={onBack}>
            <span className="xbtn">
              <ChevronLeft size={18} />
            </span>
          </button>
        )}
        <div className="grow">
          <div className="small">{variant === 'current' && styleId === 'circle' ? 'Calm circle' : 'Rolling hill'}</div>
          <div className="tiny dim">Breathe with the motion</div>
        </div>
        {variant === 'current' && (
          <button className="tap" style={{ width: 'auto' }} onClick={() => setShowCadence(true)}>
            <span className="pill">
              <Gauge size={15} /> {cadence.pattern}
            </span>
          </button>
        )}
      </div>

      {/* visual */}
      <div style={{ flex: 1, display: 'grid', placeItems: 'center', position: 'relative' }}>
        {styleId === 'hill' ? (
          <div style={{ width: '100%', height: 280, position: 'relative' }}>
            <HillCanvas phases={cadence.phases} startRef={startRef} />
            <span
              className="pill"
              style={{ position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)' }}
            >
              <Wind size={14} color="#5B9CF0" /> {label}
            </span>
          </div>
        ) : (
          <>
            <div className="breathe-ring" style={{ '--orb-scale': scale, '--phase-dur': `${dur}s` }} />
            <div className="breathe-orb" style={{ '--orb-scale': scale, '--phase-dur': `${dur}s` }}>
              {label}
            </div>
          </>
        )}
      </div>

      {/* redesign: cadence chips (a distinct visual language, not a hero card) */}
      {variant === 'redesign' && (
        <div style={{ padding: '0 25px 4px', position: 'relative', zIndex: 2 }}>
          <div className="tiny dim" style={{ marginBottom: 8 }}>
            Cadence
          </div>
          <div className="chips">
            {cadences.map((c) => (
              <button
                key={c.id}
                className={`chip${c.id === cadenceId ? ' on' : ''}`}
                onClick={() => setCadenceId(c.id)}
              >
                {c.title} · {c.pattern}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* round / time pill */}
      <div style={{ display: 'grid', placeItems: 'center', padding: '14px 0 6px' }}>
        <span className="pill dim">
          ◌ Round {round} · {mm}:{ss}
        </span>
      </div>

      {/* done */}
      <div style={{ padding: '0 25px 38px', position: 'relative', zIndex: 2 }}>
        <button className="tap" onClick={finish}>
          <div className="gbtn" style={{ background: 'var(--g-meditation)', justifyContent: 'center' }}>
            <span className="small" style={{ color: '#fff' }}>
              Done
            </span>
          </div>
        </button>
      </div>

      {/* cadence sheet (current variant — faithful gradient cards) */}
      {showCadence && (
        <Sheet onClose={() => setShowCadence(false)}>
          <div style={{ padding: '24px 25px' }}>
            <div className="h3">Cadence</div>
            <div className="small dim" style={{ marginTop: 4, marginBottom: 20 }}>
              Pick a breathing pattern.
            </div>
            <div className="stack" style={{ gap: 14 }}>
              {cadences.map((c) => (
                <button
                  key={c.id}
                  className="tap"
                  onClick={() => {
                    setCadenceId(c.id)
                    setShowCadence(false)
                  }}
                >
                  <div className="card row on-gradient" style={{ background: 'var(--g-meditation)' }}>
                    <Wind size={22} color="#fff" style={{ flexShrink: 0 }} />
                    <div className="grow">
                      <div className="small">
                        {c.title} · {c.pattern}
                      </div>
                      <div className="tiny dim75">{c.subtitle}</div>
                    </div>
                    {c.id === cadenceId && <Check size={18} color="#fff" />}
                  </div>
                </button>
              ))}
            </div>
          </div>
        </Sheet>
      )}

      {/* celebration */}
      {done && (
        <div className="overlay">
          <div className="card card-plain fade-in" style={{ textAlign: 'center', padding: 28 }}>
            <div className="medallion" style={{ background: 'var(--g-meditation)', margin: '0 auto 16px' }}>
              <Wind size={36} color="#fff" />
            </div>
            <div className="h3">{reward}</div>
            <div className="small dim" style={{ marginTop: 8 }}>
              {round} rounds · {mm}:{ss} breathed
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function elapsedSeed() {
  // deterministic-ish seed so reward varies without Math.random ban concerns
  return (Date.now() % 1000) / 1000
}

// ---------- Rolling-hill visual (ports RollercoasterScene from BreathingStyles.swift) ----------
// A wave-shaped track (one breath cycle fitted to the width) scrolls right-to-left under a
// ball fixed at center. Ball height = the breath curve value at "now".
function smoothstep(x) {
  const c = Math.max(0, Math.min(1, x))
  return c * c * (3 - 2 * c)
}

function HillCanvas({ phases, startRef }) {
  const canvasRef = useRef(null)

  useEffect(() => {
    const canvas = canvasRef.current
    const ctx = canvas.getContext('2d')
    const dpr = window.devicePixelRatio || 1
    let raf

    const cycle = Math.max(0.001, phases.inhale + phases.holdIn + phases.exhale + phases.holdOut)
    const e1 = phases.inhale
    const e2 = phases.inhale + phases.holdIn
    const e3 = e2 + phases.exhale

    function value(c) {
      const t = c * cycle
      if (t < e1) return smoothstep(t / Math.max(0.001, phases.inhale))
      if (t < e2) return 1
      if (t < e3) return 1 - smoothstep((t - e2) / Math.max(0.001, phases.exhale))
      return 0
    }

    function size() {
      const r = canvas.getBoundingClientRect()
      canvas.width = r.width * dpr
      canvas.height = r.height * dpr
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
      return r
    }

    function draw() {
      const { width: w, height: h } = canvas.getBoundingClientRect()
      ctx.clearRect(0, 0, w, h)
      const ballX = w / 2
      const baseY = h * 0.74
      const amp = baseY - h * 0.2
      const speed = w / cycle
      const elapsed = (Date.now() - startRef.current) / 1000
      const stride = 3

      const yAt = (px) => {
        const wt = elapsed + (px - ballX) / speed
        let mod = wt % cycle
        if (mod < 0) mod += cycle
        return baseY - value(mod / cycle) * amp
      }

      // filled area under the curve
      ctx.beginPath()
      ctx.moveTo(0, yAt(0))
      for (let px = stride; px <= w; px += stride) ctx.lineTo(px, yAt(px))
      ctx.lineTo(w, h)
      ctx.lineTo(0, h)
      ctx.closePath()
      ctx.fillStyle = 'rgba(91,156,240,0.18)'
      ctx.fill()

      // wave top
      ctx.beginPath()
      ctx.moveTo(0, yAt(0))
      for (let px = stride; px <= w; px += stride) ctx.lineTo(px, yAt(px))
      ctx.strokeStyle = '#5B9CF0'
      ctx.lineWidth = 4
      ctx.lineCap = 'round'
      ctx.lineJoin = 'round'
      ctx.stroke()

      // dashed "now" line
      ctx.beginPath()
      ctx.setLineDash([3, 5])
      ctx.moveTo(ballX, h * 0.12)
      ctx.lineTo(ballX, baseY + 18)
      ctx.strokeStyle = 'rgba(91,156,240,0.3)'
      ctx.lineWidth = 1
      ctx.stroke()
      ctx.setLineDash([])

      // ball at center
      const by = yAt(ballX) - 18
      ctx.beginPath()
      ctx.arc(ballX, by, 30, 0, Math.PI * 2)
      ctx.fillStyle = 'rgba(91,156,240,0.18)'
      ctx.fill()
      ctx.beginPath()
      ctx.arc(ballX, by, 16, 0, Math.PI * 2)
      ctx.fillStyle = '#fff'
      ctx.fill()
      ctx.lineWidth = 3
      ctx.strokeStyle = '#5B9CF0'
      ctx.stroke()

      raf = requestAnimationFrame(draw)
    }

    size()
    draw()
    window.addEventListener('resize', size)
    return () => {
      cancelAnimationFrame(raf)
      window.removeEventListener('resize', size)
    }
  }, [phases, startRef])

  return <canvas ref={canvasRef} style={{ width: '100%', height: '100%', display: 'block' }} />
}
