// Custom service worker for font preloading
const CACHE_NAME = 'seol-haru-check-fonts-v1';
const FONT_URLS = [
  'assets/fonts/pretendard/Pretendard-Regular.otf',
  'assets/fonts/pretendard/Pretendard-Medium.otf',
  'assets/fonts/pretendard/Pretendard-Bold.otf'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(FONT_URLS))
  );
});

self.addEventListener('fetch', (event) => {
  if (FONT_URLS.some(url => event.request.url.includes(url))) {
    event.respondWith(
      caches.match(event.request)
        .then((response) => {
          return response || fetch(event.request);
        })
    );
  }
});