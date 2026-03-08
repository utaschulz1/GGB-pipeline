let currentSlide = 0;

        function showSlide(index) {
            const slides = document.querySelector('.slides');
            const totalSlides = slides.children.length;
            if (index >= totalSlides) {
                currentSlide = 0;
            } else if (index < 0) {
                currentSlide = totalSlides - 1;
            } else {
                currentSlide = index;
            }
            console.log('Current Slide:', currentSlide);
            slides.style.transform = 'translateX(' + (-currentSlide * 100) + '%)';
        }

        function changeSlide(direction) {
            console.log('Direction:', direction);
            showSlide(currentSlide + direction);
        }

        // Show the first slide initially
        showSlide(currentSlide);