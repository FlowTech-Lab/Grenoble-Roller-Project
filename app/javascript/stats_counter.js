// Stats Counter Animation with Intersection Observer
// Animates numbers from 0 to target value when section enters viewport

document.addEventListener('DOMContentLoaded', () => {
  const statsSection = document.getElementById('stats-section');
  if (!statsSection) return;

  const statNumbers = statsSection.querySelectorAll('.stat-number');
  if (statNumbers.length === 0) return;

  // Animation function
  function animateValue(element, start, end, duration) {
    const startTime = performance.now();
    const isInteger = Number.isInteger(end);

    function update(currentTime) {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      
      // Ease-out easing function
      const easeOut = 1 - Math.pow(1 - progress, 3);
      
      let current = start + (end - start) * easeOut;
      
      if (isInteger) {
        current = Math.floor(current);
      } else {
        current = parseFloat(current.toFixed(1));
      }
      
      element.textContent = current;
      
      if (progress < 1) {
        requestAnimationFrame(update);
      } else {
        element.textContent = end; // Ensure final value is exact
      }
    }
    
    requestAnimationFrame(update);
  }

  // Intersection Observer
  const observerOptions = {
    root: null,
    rootMargin: '0px',
    threshold: 0.3 // Trigger when 30% of section is visible
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        statNumbers.forEach(stat => {
          const target = parseInt(stat.getAttribute('data-target'), 10);
          if (target && stat.textContent === '0') {
            animateValue(stat, 0, target, 1500); // 1.5s duration
          }
        });
        
        // Unobserve after animation starts
        observer.unobserve(entry.target);
      }
    });
  }, observerOptions);

  observer.observe(statsSection);
});

