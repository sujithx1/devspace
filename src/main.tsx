import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
// Installs role-based write checks into the stores.
import './stores/permissions'
import './index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
