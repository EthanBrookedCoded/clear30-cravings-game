import { Flame, Moon, Sparkles, Leaf, Stethoscope, User, MessageSquareText } from 'lucide-react'
import { HeroCard } from './ui'

const emojis = ['🤩', '🤔', '🥺', '🤢', '🫥', '😡', '🫨', '🫠']

// Faithful port of the sandbox MockSupportView / real app Support tab.
export default function SupportTab({ onOpenCravings }) {
  return (
    <div style={{ padding: '64px 25px 40px' }}>
      <div className="h2">Support</div>
      <div className="small dim" style={{ marginTop: 6, marginBottom: 28 }}>
        Help when you need it most.
      </div>

      <div className="section-label">Immediate support</div>
      <div className="stack" style={{ gap: 14, marginBottom: 28 }}>
        <HeroCard
          icon={Leaf}
          gradient="var(--g-clear30)"
          title="Slip up?"
          subtitle="A moment of support"
          onClick={() => {}}
        />
        <HeroCard
          icon={Flame}
          gradient="var(--g-red)"
          title="Cravings"
          subtitle="Help is here"
          onClick={onOpenCravings}
        />
        <HeroCard
          icon={Moon}
          gradient="var(--g-sleep)"
          title="Sleep"
          subtitle="Wind down"
          onClick={() => {}}
        />

        {/* Claire compact */}
        <div className="card on-gradient" style={{ background: 'var(--g-claire)' }}>
          <div className="row" style={{ gap: 8, marginBottom: 8 }}>
            <Sparkles size={17} color="#fff" />
            <span className="small">Claire</span>
          </div>
          <div className="tiny dim75" style={{ marginBottom: 14 }}>
            Chat or tap how you're feeling
          </div>
          <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 2 }}>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                background: '#fff',
                borderRadius: 14,
                padding: '0 16px',
                height: 42,
                flexShrink: 0,
              }}
            >
              <MessageSquareText size={16} color="#6B6CF4" />
              <span className="tiny" style={{ color: '#6B6CF4' }}>
                Chat
              </span>
            </div>
            {emojis.map((e) => (
              <div
                key={e}
                style={{
                  width: 42,
                  height: 42,
                  borderRadius: 14,
                  background: 'rgba(255,255,255,0.5)',
                  display: 'grid',
                  placeItems: 'center',
                  fontSize: 22,
                  flexShrink: 0,
                }}
              >
                {e}
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="section-label">Human support</div>
      <div className="stack" style={{ gap: 14 }}>
        <HumanRow icon={Stethoscope} name="Dr. Fred" role="Addiction specialist" grad="var(--g-meditation)" />
        <HumanRow icon={User} name="Gerad" role="Accountability buddy" grad="linear-gradient(135deg,#5B9CF0,#448eee)" />
      </div>
    </div>
  )
}

function HumanRow({ icon: Icon, name, role, grad }) {
  return (
    <div className="card row on-gradient" style={{ background: grad }}>
      <div className="icon-circle">
        <div className="halo" />
        <div className="disc">
          <Icon size={22} color="#5B9CF0" strokeWidth={2.3} />
        </div>
      </div>
      <div className="grow">
        <div className="small">{name}</div>
        <div className="tiny dim75">{role}</div>
      </div>
    </div>
  )
}
