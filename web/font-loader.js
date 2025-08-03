// 폰트 로딩 전용 스크립트
(function() {
  'use strict';
  
  // 폰트 로딩 상태 관리
  let fontsLoaded = false;
  
  // 폰트 로딩 함수
  function loadPretendardFonts() {
    const fontPromises = [
      new FontFace('Pretendard', 'url(assets/assets/fonts/pretendard/Pretendard-Regular.otf)', { weight: '400' }).load(),
      new FontFace('Pretendard', 'url(assets/assets/fonts/pretendard/Pretendard-Medium.otf)', { weight: '500' }).load(),
      new FontFace('Pretendard', 'url(assets/assets/fonts/pretendard/Pretendard-Bold.otf)', { weight: '700' }).load(),
      new FontFace('Pretendard', 'url(assets/assets/fonts/pretendard/Pretendard-Light.otf)', { weight: '300' }).load(),
      new FontFace('Pretendard', 'url(assets/assets/fonts/pretendard/Pretendard-SemiBold.otf)', { weight: '600' }).load()
    ];
    
    return Promise.all(fontPromises).then(fonts => {
      fonts.forEach(font => document.fonts.add(font));
      fontsLoaded = true;
      document.body.classList.add('pretendard-loaded');
      console.log('Pretendard fonts loaded successfully');
      return fonts;
    }).catch(error => {
      console.warn('Failed to load Pretendard fonts:', error);
      // 폰트 로딩 실패 시에도 앱이 동작하도록 함
      document.body.classList.add('pretendard-fallback');
      return [];
    });
  }
  
  // DOM이 준비되면 폰트 로딩 시작
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadPretendardFonts);
  } else {
    loadPretendardFonts();
  }
  
  // 전역 함수로 노출
  window.isPretendardLoaded = () => fontsLoaded;
})();