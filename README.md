# 서재 — iOS 네이티브 앱 (백그라운드 TTS)

웹 버전(PWA)은 화면이 잠기면 iOS가 읽어주기(speechSynthesis)를 강제로
멈춰버려서 배경 재생이 근본적으로 불가능했습니다. 이 프로젝트는 같은
리더 앱을 [Capacitor](https://capacitorjs.com)로 감싸서 iOS 기본
읽어주기 엔진(AVSpeechSynthesizer)을 직접 쓰는 네이티브 앱으로 만든
것입니다 — 화면이 꺼지거나 잠겨도, 다른 앱으로 전환해도 계속 읽어줍니다.

TTS는 요청대로 단순하게 구현했습니다: 챕터 전체를 순서대로 읽고,
재생 · 일시정지 · 정지만 지원합니다 (문장 단위 건너뛰기 등은 웹
버전에만 있습니다).

## Mac 없이 ipa 만들기 (GitHub Actions)

Xcode는 macOS에서만 돌아가는데, Mac이 없어도 GitHub이 무료로 제공하는
macOS 빌드 서버로 대신 빌드할 수 있습니다.

1. 이 폴더를 그대로 새 GitHub 저장소에 올립니다 (private 저장소도 됩니다).
   ```
   git init
   git add .
   git commit -m "init"
   git branch -M main
   git remote add origin <내 저장소 주소>
   git push -u origin main
   ```
2. GitHub 저장소 페이지 → **Actions** 탭 → `Build unsigned IPA (for SideStore)`
   워크플로우가 자동으로 시작됩니다 (안 보이면 **Run workflow** 버튼을
   눌러 수동 실행). 5~10분 정도 걸립니다.
3. 빌드가 끝나면 해당 실행 결과 페이지 하단 **Artifacts**에서
   `서재-ipa`를 다운로드합니다. 압축을 풀면 `서재-unsigned.ipa`가
   나옵니다.

## SideStore로 설치하기

1. 아이폰에 SideStore/AltServer 페어링이 이미 되어 있어야 합니다
   (처음 설정은 SideStore 공식 가이드를 따라주세요).
2. 위에서 받은 `서재-unsigned.ipa`를 아이폰으로 옮깁니다 (에어드랍,
   파일 앱 등 편한 방법으로).
3. SideStore 앱에서 **+** 버튼 → 이 ipa 파일 선택 → 설치.
   서명은 SideStore가 자동으로 처리합니다.
4. 무료 Apple ID로 서명한 경우 7일마다 SideStore에서 재서명(새로고침)
   해줘야 계속 실행됩니다. 이건 SideStore 자체의 제약이라 이 앱만의
   문제는 아닙니다.

## 이 프로젝트 구조

```
www/                          웹 리더 앱 (기존 파일 그대로)
ios/App/App/TTSPlugin.swift   네이티브 읽어주기 플러그인 (직접 추가)
ios/App/App/Info.plist        UIBackgroundModes(audio) 추가됨
.github/workflows/build-ipa.yml   GitHub Actions 자동 빌드
```

`www/app.js`는 Capacitor 네이티브 환경에서 실행 중인지 자동으로
감지해서, 네이티브에서는 `TTSPlugin`을, 일반 웹 브라우저에서는 기존
Web Speech API를 사용하도록 분기되어 있습니다. 즉 같은 `www/` 폴더를
그대로 웹에 올려도 여전히 정상 동작합니다.

## 직접 코드를 고치고 싶다면

`www/` 안의 파일(index.html, app.js, styles.css)을 수정한 뒤:
```
npx cap sync ios
```
을 실행하면 iOS 프로젝트에 반영됩니다. 그 다음 다시 GitHub에 푸시하면
Actions가 새 ipa를 만들어줍니다.

## 알아둘 점

- 이 ipa는 서명되지 않은 상태로 만들어집니다. SideStore/AltStore
  계열은 원래 설치 시 자체적으로 서명하는 구조라 문제없습니다.
- 앱 아이콘은 웹 버전의 아이콘(icon-192/512.png)을 아직 iOS 전용
  아이콘 세트로 별도 변환하지 않았습니다 — 기본 Capacitor 아이콘으로
  나올 수 있습니다. 원하시면 말씀해 주세요, 아이콘 세트를 만들어
  넣어드리겠습니다.
