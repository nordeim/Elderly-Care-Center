import Alpine from 'alpinejs'
import '@phosphor-icons/web'

import { initScrollAnimations } from './lib/animations'
import { setupTestimonialsCarousel } from './lib/testimonials'

window.Alpine = Alpine

const boot = () => {
  Alpine.start()
  initScrollAnimations()
  setupTestimonialsCarousel()
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', boot, { once: true })
} else {
  boot()
}
