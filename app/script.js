// Test CORS functionality
console.log('CloudFront script loaded');

// Test fetch with CORS
fetch('/videos/video.mp4', {
    method: 'HEAD'
})
.then(response => {
    console.log('CORS test successful:', response.status);
    console.log('Headers:', [...response.headers.entries()]);
})
.catch(error => {
    console.error('CORS test failed:', error);
});

// Display cache headers
fetch(window.location.href)
.then(response => {
    console.log('Cache-Control:', response.headers.get('cache-control'));
    console.log('CloudFront headers:', {
        'cf-cache-status': response.headers.get('x-cache'),
        'cf-pop': response.headers.get('cloudfront-viewer-country')
    });
});