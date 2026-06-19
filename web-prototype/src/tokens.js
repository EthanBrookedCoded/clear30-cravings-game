// Design tokens lifted 1:1 from the real app's Colors.swift + GlobalData.swift
// so the prototype reads as Clear30, not as a generic web app.

export const colors = {
  blue: '#5BB4A9',
  green: '#80C97A',
  yellow: '#FFF87E',
  meditation1: '#5B9CF0',
  meditation2: '#5BAEE6',
  // light-mode resolutions of the dynamic system colors
  background: '#FFFFFF',
  button: '#F1F1F5', // secondarySystemBackground
  text: '#1C1C1E',
  shadow: 'rgba(0,0,0,0.22)',
  opacityGray: 'rgba(120,120,128,0.22)',
}

// Gradient direction note: SwiftUI leading->trailing == CSS 90deg (to right).
// bottomLeading->topTrailing == CSS to top right.
export const gradients = {
  clear30: 'linear-gradient(90deg, #5BB4A9 0%, #80C97A 100%)',
  clear30Bright: 'linear-gradient(45deg, #26CD6A 0%, #00BCA5 100%)',
  meditation: 'linear-gradient(90deg, #5B9CF0 0%, #5BAEE6 100%)',
  claire: 'linear-gradient(90deg, #5C70EF 0%, #8969FF 100%)',
  red: 'linear-gradient(45deg, #f65555 0%, #fb5151 100%)',
  sleep: 'linear-gradient(45deg, #14435E 0%, #1C5E80 100%)',
  symptom: 'linear-gradient(45deg, #FF8C59 0%, #FFA372 100%)', // warm orange — used for Games
}

// Spacing scale from GlobalData
export const space = {
  cardSpacing: 14,
  horizontalPadding: 25,
  headingTopPadding: 10,
  cornerRadius: 21,
}
