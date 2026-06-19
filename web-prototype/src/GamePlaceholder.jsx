import { useState } from 'react'
import { X, Gamepad2, Flag } from 'lucide-react'

// Stand-in for the real SwiftUI games. The point of the prototype is navigation,
// so this just simulates "play a round → complete" with a quit affordance.
export default function GamePlaceholder({ title, level, gradient, onComplete, onQuit }) {
  const [taps, setTaps] = useState(0)
  const goal = 6

  function tap() {
    const n = taps + 1
    setTaps(n)
    if (n >= goal) setTimeout(() => onComplete(n), 280)
  }

  return (
    <div style={{ position: 'relative', height: '100%', minHeight: '100%', display: 'flex', flexDirection: 'column', background: 'var(--c-bg)' }}>
      <div className="row" style={{ padding: '16px 25px 0' }}>
        <div className="grow">
          <div className="small">{title}</div>
          <div className="tiny dim">Tap the orb to play it out</div>
        </div>
        <span className="pill" style={{ marginRight: 10 }}>
          <Flag size={13} /> Lvl {level}
        </span>
        <button className="tap" style={{ width: 'auto' }} onClick={onQuit}>
          <span className="xbtn">
            <X size={16} />
          </span>
        </button>
      </div>

      <div style={{ flex: 1, display: 'grid', placeItems: 'center', gap: 24 }}>
        <button
          className="tap"
          style={{ width: 'auto' }}
          onClick={tap}
        >
          <div
            style={{
              width: 170,
              height: 170,
              borderRadius: '50%',
              background: gradient,
              display: 'grid',
              placeItems: 'center',
              color: '#fff',
              boxShadow: '0 18px 50px rgba(0,0,0,0.25)',
              transform: `scale(${1 + taps * 0.03})`,
              transition: 'transform 0.2s cubic-bezier(0.2,1.3,0.4,1)',
            }}
          >
            <Gamepad2 size={52} />
          </div>
        </button>
        <div className="small dim">
          {taps} / {goal} — a real game lives here in the app
        </div>
      </div>
    </div>
  )
}
