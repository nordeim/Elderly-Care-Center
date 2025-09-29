import EmblaCarousel from 'embla-carousel'

let emblaInstance
let autoplayId

function startAutoplay(embla, delay = 5000) {
  stopAutoplay()
  autoplayId = window.setInterval(() => {
    if (!embla || embla.destroyed) {
      stopAutoplay()
      return
    }

    if (embla.canScrollNext()) {
      embla.scrollNext()
    } else {
      embla.scrollTo(0)
    }
  }, delay)
}

function stopAutoplay() {
  if (autoplayId) {
    window.clearInterval(autoplayId)
    autoplayId = undefined
  }
}

export function setupTestimonialsCarousel() {
  const container = document.querySelector('[data-testimonials]')

  if (!container) {
    return
  }

  const viewport = container.querySelector('[data-testimonials-viewport]')
  const dots = Array.from(container.querySelectorAll('[data-testimonials-dot]'))

  if (!viewport) {
    return
  }

  emblaInstance = EmblaCarousel(viewport, {
    loop: true,
    align: 'start'
  })

  const updateDots = () => {
    const selectedSnap = emblaInstance.selectedScrollSnap()
    dots.forEach((dot, index) => {
      dot.classList.toggle('opacity-100', index === selectedSnap)
      dot.classList.toggle('opacity-40', index !== selectedSnap)
    })
  }

  emblaInstance.on('select', updateDots)
  emblaInstance.on('init', () => {
    updateDots()
    startAutoplay(emblaInstance)
  })

  container.addEventListener('mouseenter', stopAutoplay)
  container.addEventListener('mouseleave', () => startAutoplay(emblaInstance))

  dots.forEach((dot, index) => {
    dot.addEventListener('click', () => {
      emblaInstance.scrollTo(index)
    })
  })

  window.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      stopAutoplay()
    } else {
      startAutoplay(emblaInstance)
    }
  })
}
