// ©AngelaMos | 2026
// theme.js

;(() => {
  let theme = 'dark'
  const isHome = location.pathname === '/'
  try {
    if (!isHome && localStorage.getItem('angelamos-theme') === 'light') {
      theme = 'light'
    }
  } catch {
    theme = 'dark'
  }
  document.documentElement.dataset.theme = theme
  document.documentElement.dataset.page = isHome ? 'home' : 'inner'
})()
