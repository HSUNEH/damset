---
type: tools
status: active
updated: "2026-07-19"
tags: [tools, workflow, routing]
sources:
  - Package.swift
  - project.yml
  - docs/qa-automation.md
  - docs/install.md
  - docs/assets/damset-hero.jpg
---

# 도구와 행동 방식

## 기본 행동

1. `git status --short`로 사용자 변경을 먼저 보호한다.
2. `rg`, `rg --files`로 관련 심볼·파일·테스트·이력을 좁힌다.
3. 변경하려는 동작의 현재 테스트와 호출자를 읽고 가장 작은 경계에서 고친다.
4. 코드 변경과 같은 턴에 테스트, 관련 위키, 완료 로그를 맞춘다.
5. 외부 상태나 Apple 정책처럼 변할 수 있는 사실은 현재 명령 또는 공식
   문서로 다시 확인하고 확인 날짜를 적는다.

## 작업별 라우팅

| 작업 | 우선 도구·행동 | 최소 확인 |
| --- | --- | --- |
| 심볼/호출자 찾기 | `rg -n`, `rg --files`; 필요하면 `git log -S`/`git blame` | 현재 구현과 테스트를 함께 읽음 |
| 코어 상태 전이 | `Sources/DamSetCore`, 기존 XCTest에 사례 추가 | `swift test`, `swift run DamSetCoreSmoke` |
| SwiftUI 화면 | 앱 셸로 빠른 컴파일, 실제 iOS 타깃 빌드; 시각 변경은 스크린 관찰 | `swift test`, `xcodebuild`; 레이아웃은 스크린샷 |
| Live Activity/App Intent | 코어 동기화 경로를 재사용; 앱과 확장 타깃 모두 확인 | `xcodebuild`; 상호작용은 시뮬레이터, 최종 감각은 실기기 |
| 저장/마이그레이션 | 임시 파일 기반 round-trip·이전 JSON 디코딩 테스트 | 단위 테스트, 스모크, 재실행 복원 |
| 프로젝트/서명 | `project.yml` 수정 → `~/.local/bin/xcodegen generate` | 생성 diff 검토, 전체 iOS 빌드 |
| 휴식 알림/오디오 | 벽시계와 앱 상태를 분리해 검증; 포그라운드/잠금 경로 구분 | 엔진 테스트 + 시뮬레이터 + 필요 시 실기기 |
| 제품 문서 | 실제 UI 문자열·현재 명령과 대조 | 링크, 명령, `git diff --check` |
| README/홍보 이미지 | iPhone Mirroring 실기기 캡처를 UI 근거로 삼고 기존 아트의 구도·분위기만 참조해 합성 | 실제 화면과 최종 이미지를 나란히 보고 문구·계층·색·캡처 오버레이 확인 |
| 위키 유지 | 기존 페이지 검색 후 통합; 새 페이지면 인덱스 연결 | `ruby Scripts/check_agent_wiki.rb` |

## 도구 선택 원칙

- 정적 사실은 파일 검색과 테스트로 확인한다. UI를 열 필요가 없는 일을
  브라우저나 데스크톱 자동화로 우회하지 않는다.
- 실제 렌더링·권한·잠금 상태처럼 코드만으로 판정할 수 없는 것은
  시뮬레이터 또는 기기 화면을 관찰한다.
- macOS `DamSetAppShell`은 SwiftUI 흐름의 빠른 폴백이다. ActivityKit,
  UserNotifications, 오디오·햅틱이 no-op이므로 그 결과를 iOS 기능 검증으로
  해석하지 않는다.
- 시뮬레이터는 Live Activity 표시와 Intent 흐름에 유용하지만 음악 유지,
  햅틱, 실제 잠금 화면 전달의 최종 근거가 아니다.
- 저장소에 이미 있는 명령과 스크립트를 재사용한다. 같은 절차가 두 번 이상
  복잡하게 반복되면 `Scripts/`의 작은 결정론적 도구로 승격하고 이 페이지에
  기록한다.
- 진단 요청은 원인과 근거를 먼저 제시한다. 수정 요청이면 재현 → 최소 수정
  → 회귀 검증까지 수행한다.

## Orca 작업공간의 터미널 제어

`last_verified: 2026-07-19`

- Orca 안의 터미널·분할·에이전트 실행은 데스크톱 UI 자동화보다 `orca` CLI를
  먼저 쓴다. `orca status --json`이 `runtime.ready`인지 확인한 뒤
  `orca terminal list --worktree active --json`으로 대상 핸들을 식별한다.
- 새 Codex 분할은 대상 핸들을 명시해 한 번에 만든다:
  `orca terminal split --terminal <handle> --direction horizontal --command "codex" --json`.
  기존 사용자의 패널에 `send`로 입력하지 않는다.
- 런타임이 준비되지 않았을 때는 UI를 대신 조작하지 않는다. 상태를 다시
  확인하거나 사용자에게 Orca 연결 상태를 알린다. Computer Use는 Orca 터미널
  레이아웃이 아닌 별도 데스크톱 앱 작업에만 사용한다.

## 자주 쓰는 명령

```bash
# 빠른 코어 게이트
swift test
swift run DamSetCoreSmoke

# 실제 iOS 타깃
xcodebuild -project DamSet.xcodeproj -scheme DamSet \
  -destination 'platform=iOS Simulator,name=<installed simulator>' test

# 프로젝트 재생성
~/.local/bin/xcodegen generate

# 위키와 diff
ruby Scripts/check_agent_wiki.rb
git diff --check
```

시뮬레이터 이름과 Xcode 버전은 설치 상태에 따라 달라지므로 고정값을
추측하지 말고 `xcodebuild -showdestinations`와 `xcodebuild -version`으로
확인한다.
