---
type: playbook
status: active
updated: "2026-07-19"
tags: [verification, tests, qa]
sources:
  - Package.swift
  - docs/qa-automation.md
  - README.md
---

# 검증 플레이북

## 변경별 매트릭스

| 변경 | 필수 검증 | 조건부 확장 |
| --- | --- | --- |
| 문서·위키만 | `ruby Scripts/check_agent_wiki.rb`, `git diff --check` | 문서 속 명령을 실제 실행 |
| 순수 코어 로직 | 관련 XCTest, `swift test`, `swift run DamSetCoreSmoke` | iOS 소비자가 달라지면 `xcodebuild` |
| 모델·저장 형식 | 코어 게이트 + 파일 round-trip/호환 테스트 | 재실행 또는 기존 fixture 복원 |
| SwiftUI 화면 | 코어 게이트 + 실제 앱 타깃 빌드 | 앱 셸/시뮬레이터 스크린 관찰 |
| Live Activity·Intent | 코어 게이트 + 앱·확장 전체 빌드 | 시뮬레이터 잠금 화면 상호작용 |
| 알림·오디오·햅틱 | 결정론적 엔진 테스트 + 전체 빌드 | 시뮬레이터 알림, 실기기 음악/햅틱 |
| `project.yml`·타깃 | XcodeGen 재생성 + 생성 diff + 전체 빌드/테스트 | 실기기 서명/설치 |
| 제품 전체 흐름 | 모든 자동 게이트 | 시뮬레이터 또는 실기기 end-to-end |

## 빠른 로컬 게이트

```bash
swift test
swift run DamSetCoreSmoke
ruby Scripts/check_agent_wiki.rb
git diff --check
```

필요하면 README의 전체 로컬 게이트처럼 `swift build`와 `seed.yaml` YAML
파싱도 포함한다.

## iOS 게이트

먼저 현재 설치 상태를 확인한다.

```bash
xcodebuild -version
xcodebuild -project DamSet.xcodeproj -scheme DamSet -showdestinations
```

그 결과에 실제로 있는 시뮬레이터를 사용해 테스트한다.

```bash
xcodebuild test \
  -project DamSet.xcodeproj \
  -scheme DamSet \
  -destination 'platform=iOS Simulator,name=<installed simulator>'
```

이 게이트는 앱, 코어 프레임워크, Live Activity 확장의 컴파일 결합을
검증한다. 테스트 실행이 불가능한 환경이라면 generic simulator build라도
실행하고 제한을 로그에 적는다.

## 관찰이 필요한 판정

다음은 테스트 통과나 스크린샷 한 장만으로 최종 판정하지 않는다.

- 잠금 화면과 Dynamic Island의 실제 밀도와 잘림
- 빠른 `- / + / Done` 탭의 체감과 상태 일치
- 다른 음악 재생이 휴식 종료음 뒤에도 계속되는지
- 무음 모드·Focus·알림 권한별 폴백
- 실제 햅틱과 기기 잠금 상태 전달

이 항목을 건드리지 않은 변경에 매번 실기기 QA를 요구하지는 않는다. 관련
동작을 변경했거나 출시 판단을 할 때 [기기 QA 플레이북](device-live-activity.md)을
실행한다.

## 결과 기록

- 명령과 `passed`/`failed`/`not run`을 구분한다.
- 기존 실패와 새 회귀를 구분할 근거를 남긴다.
- 수동 확인은 기기/OS, 관찰 상태, 기대와 실제를 짧게 기록한다.
- 자세한 반복 지식은 이 페이지 또는 기기 플레이북에 통합하고, 작업 로그에는
  결과 요약과 링크만 둔다.
