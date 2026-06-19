import { ChevronRight, X } from 'lucide-react'

// Representative solid tint for each gradient — used to color glyphs sitting on a
// white disc. At 22px a solid tint reads identically to the gradient and is robust.
export const tintFor = {
  'var(--g-clear30)': '#5BB4A9',
  'var(--g-meditation)': '#5B9CF0',
  'var(--g-claire)': '#6B6CF4',
  'var(--g-red)': '#F65555',
  'var(--g-sleep)': '#1C5E80',
  'var(--g-symptom)': '#FF8C59',
}

// White disc with a tinted glyph (the recurring Clear30 icon motif).
export function GlyphCircle({ icon: Icon, gradient }) {
  const tint = tintFor[gradient] || '#5BB4A9'
  return (
    <div className="icon-circle">
      <div className="halo" />
      <div className="disc">
        <Icon size={22} strokeWidth={2.3} color={tint} />
      </div>
    </div>
  )
}

// Canonical Clear30 entry card: gradient fill, white disc icon, title + subtitle.
export function HeroCard({ icon, gradient, title, subtitle, onClick, chevron = false }) {
  return (
    <button className="tap" onClick={onClick}>
      <div className="card row on-gradient" style={{ background: gradient }}>
        <GlyphCircle icon={icon} gradient={gradient} />
        <div className="grow">
          <div className="small">{title}</div>
          {subtitle && <div className="tiny dim75">{subtitle}</div>}
        </div>
        {chevron && <ChevronRight size={16} className="chev" />}
      </div>
    </button>
  )
}

export function GradientButton({ icon: Icon, gradient, text, onClick }) {
  return (
    <button className="tap" onClick={onClick}>
      <div className="gbtn" style={{ background: gradient }}>
        <div className="sq">
          <Icon size={18} color="#fff" strokeWidth={2.3} />
        </div>
        <div className="small grow" style={{ color: '#fff' }}>
          {text}
        </div>
        <ChevronRight size={14} className="chev" />
      </div>
    </button>
  )
}

export function OutlineButton({ icon: Icon, iconGradient, text, onClick }) {
  const tint = tintFor[iconGradient] || '#5BB4A9'
  return (
    <button className="tap" onClick={onClick}>
      <div className="obtn">
        {Icon && <Icon size={17} color={tint} strokeWidth={2.4} />}
        <span className="small">{text}</span>
      </div>
    </button>
  )
}

export function Sheet({ children, onClose, tall = false }) {
  return (
    <div className="sheet-scrim" onClick={onClose}>
      <div className={`sheet${tall ? ' tall' : ''}`} onClick={(e) => e.stopPropagation()}>
        <div className="sheet-chrome">
          <button className="tap chrome-close" onClick={onClose}>
            <X size={15} />
          </button>
          <div className="grabber" />
          <div style={{ width: 30 }} />
        </div>
        <div className="sheet-body">{children}</div>
      </div>
    </div>
  )
}

export function Phone({ children }) {
  return (
    <div className="phone">
      <div className="phone-screen">
        <div className="notch" />
        {children}
      </div>
    </div>
  )
}

export function SectionDivider({ text }) {
  return (
    <div className="divider">
      <div className="line" />
      <span className="tiny">{text}</span>
      <div className="line" />
    </div>
  )
}
