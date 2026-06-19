import { useState } from 'react'
import { Phone, Sheet } from './ui'
import SupportTab from './SupportTab'
import CurrentFlow from './CurrentFlow'
import RedesignFlow from './RedesignFlow'

export default function App() {
  const [mode, setMode] = useState('redesign') // 'current' | 'redesign'
  const [showCravings, setShowCravings] = useState(false)

  return (
    <div className="stage">
      <div className="stage-head">
        <h1>Clear30 · Cravings navigation prototype</h1>
        <p>
          Tap <b>Cravings</b> in the Support tab to open the flow. Flip the toggle to compare
          today’s navigation with the proposed category-hub redesign.
        </p>
      </div>

      <div className="switcher">
        <button className={mode === 'current' ? 'active' : ''} onClick={() => setMode('current')}>
          Current
        </button>
        <button className={mode === 'redesign' ? 'active' : ''} onClick={() => setMode('redesign')}>
          Redesign
        </button>
      </div>

      <Phone>
        <div className="surface">
          <SupportTab onOpenCravings={() => setShowCravings(true)} />
        </div>

        {showCravings && (
          <Sheet key={mode} onClose={() => setShowCravings(false)} tall>
            {mode === 'current' ? <CurrentFlow /> : <RedesignFlow />}
          </Sheet>
        )}
      </Phone>

      <div className="note">
        {mode === 'current' ? (
          <>
            <b>Current:</b> craving sheet asks intensity first, each level routes to one game, and
            the post-game screen carries everything (best score, rating, “still craving?”, a 12-level
            grid, and four actions). Meditations aren’t reachable here.
          </>
        ) : (
          <>
            <b>Redesign:</b> a category hub surfaces Meditations, Breathwork, and Games up front —
            each with its own visual language (audio rail · feature panel · tile grid) so nothing
            reads like the red Cravings button. Breathwork is rolling-hill + cadence chips with a
            back button; post-game is just “Level N complete → Next level / Done,” with the current
            level highlighted in the selector.
          </>
        )}
      </div>
    </div>
  )
}
