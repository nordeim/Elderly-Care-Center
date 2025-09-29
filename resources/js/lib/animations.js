const prefersReducedMotion = () =>
  window.matchMedia('(prefers-reduced-motion: reduce)').matches

export function initScrollAnimations() {
  if (prefersReducedMotion()) {
    return
  }

  const animatedElements = document.querySelectorAll('[data-animate]')

  if (!animatedElements.length) {
    return
  }

  const observer = new IntersectionObserver(
    entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const target = entry.target
          const delay = Number.parseInt(target.dataset.animateDelay || '0', 10)

          if (delay) {
            target.style.animationDelay = `${delay}ms`
          }

          target.classList.add('animate-fade-in-up')
          target.classList.remove('opacity-0', 'translate-y-5')
          observer.unobserve(target)
        }
      })
    },
    {
      rootMargin: '0px 0px -10% 0px',
      threshold: 0.1
    }
  )

  animatedElements.forEach(element => {
    element.classList.add('opacity-0', 'translate-y-5')
    observer.observe(element)
  })
}
