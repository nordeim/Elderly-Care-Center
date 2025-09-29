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
          entry.target.classList.add('animate-fade-in-up')
          observer.unobserve(entry.target)
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
