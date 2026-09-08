/* 서재 Premium Reader — Service Worker (오프라인 지원) */
const CACHE = 'seojae-reader-v5';

/* 설치 시 미리 캐싱할 앱 셸 + 핵심 라이브러리 */
const PRECACHE = [
  './',
  './index.html',
  './styles.css',
  './app.js',
  './manifest.webmanifest',
  './icon-192.png',
  './icon-512.png',
  './icon-180.png',
  /* CDN 핵심 라이브러리 (첫 로드 시 캐싱해 오프라인에서도 문서 변환 가능) */
  'https://cdn.jsdelivr.net/npm/mammoth@1.8.0/mammoth.browser.min.js',
  'https://cdn.jsdelivr.net/npm/marked@12.0.2/marked.min.js',
  'https://cdn.jsdelivr.net/npm/dompurify@3.0.11/dist/purify.min.js',
  'https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js',
  'https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.min.js',
  'https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.worker.min.js'
];

/* 런타임 캐싱 대상 오리진 */
const FONT_ORIGINS = ['https://fonts.googleapis.com', 'https://fonts.gstatic.com'];
const CDN_ORIGIN = 'https://cdn.jsdelivr.net';

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE).then((c) =>
      Promise.all(
        PRECACHE.map((url) =>
          fetch(url, { mode: 'cors' }).then((res) => {
            if (res.ok) return c.put(url, res.clone());
          }).catch(() => {}) /* 일부 리소스 실패해도 설치는 계속 */
        )
      )
    ).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  const isNavigation = req.mode === 'navigate';
  const isSameOrigin = url.origin === self.location.origin;
  const isFont = FONT_ORIGINS.includes(url.origin);
  const isCDN = url.origin === CDN_ORIGIN;

  /* 1) 페이지 이동: 네트워크 우선 → 실패 시 캐시(오프라인) */
  if (isNavigation) {
    e.respondWith(
      fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put(req, copy));
          return res;
        })
        .catch(() => caches.match(req).then((r) => r || caches.match('./index.html')))
    );
    return;
  }

  /* 2) 폰트/CDN 리소스: 캐시 우선(빠르고 오프라인 가능) → 백그라운드 갱신 */
  if (isFont || isCDN || (isSameOrigin && !url.pathname.endsWith('.html'))) {
    e.respondWith(
      caches.match(req).then((cached) => {
        const network = fetch(req)
          .then((res) => {
            if (res && (res.ok || res.type === 'opaque')) {
              const copy = res.clone();
              caches.open(CACHE).then((c) => c.put(req, copy));
            }
            return res;
          })
          .catch(() => cached);
        return cached || network;
      })
    );
    return;
  }

  /* 3) 기타 동일 출처 요청: stale-while-revalidate */
  if (isSameOrigin) {
    e.respondWith(
      caches.match(req).then((cached) => {
        const network = fetch(req)
          .then((res) => {
            const copy = res.clone();
            caches.open(CACHE).then((c) => c.put(req, copy));
            return res;
          })
          .catch(() => cached);
        return cached || network;
      })
    );
  }
});
