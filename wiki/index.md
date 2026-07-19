---
type: index
status: active
updated: "2026-07-19"
tags: [agent-wiki, navigation]
---

# DamSet agent wiki

DamSet 작업에 앞서 읽는 지식 지도다. 원본 코드를 매번 처음부터 재해석하지
않도록 제품 의도, 구조, 도구 선택, 검증법, 결정의 이유를 연결한다. 현재
코드·테스트·설정이 최종 근거이며 위키는 그 근거를 압축한 운영 지식이다.

## 작업 라우팅

| 작업 | 먼저 읽을 페이지 |
| --- | --- |
| 모든 작업 | [운영 스키마](schema.md), [최근 작업 로그](log.md) |
| 기능 범위·UX 판단 | [제품과 불변 조건](product.md) |
| 상태 머신·저장·동기화 | [시스템 구조](architecture.md), [정규 세션 결정](decisions/0001-canonical-session-sync.md) |
| 도구 선택·일반 구현 | [도구와 행동 방식](tools.md), [코드 변경 플레이북](playbooks/code-change.md) |
| 테스트 범위 결정 | [검증 플레이북](playbooks/verification.md) |
| Live Activity·실기기·서명 | [기기와 Live Activity QA](playbooks/device-live-activity.md), [프로젝트 생성과 서명 결정](decisions/0002-project-generation-and-signing.md) |
| 프로젝트/타깃 설정 | [도구와 행동 방식](tools.md), [프로젝트 생성과 서명 결정](decisions/0002-project-generation-and-signing.md) |
| 위키 구조 변경·정리 | [운영 스키마](schema.md), [도구와 행동 방식](tools.md) |

## 핵심 페이지

- [운영 스키마](schema.md) — 지식 계층, 출처 우선순위, 페이지와 로그 규칙
- [제품과 불변 조건](product.md) — 사용자 흐름, 범위, UX에서 깨지면 안 되는 것
- [시스템 구조](architecture.md) — 타깃, 상태 머신, 저장과 Live Activity 동기화
- [도구와 행동 방식](tools.md) — 작업 유형별 탐색·수정·검증 도구
- [코드 변경 플레이북](playbooks/code-change.md) — 구현 전·중·후의 기본 순서
- [검증 플레이북](playbooks/verification.md) — 변경 위험에 비례한 검증 매트릭스
- [기기와 Live Activity QA](playbooks/device-live-activity.md) — 시뮬레이터와 실기기 경계
- [최근 작업 로그](log.md) — 위키와 앱이 어떻게 변했는지 보여 주는 시간순 기록

## 결정

- [ADR-0001: 정규 세션과 단일 동기화 파이프라인](decisions/0001-canonical-session-sync.md)
- [ADR-0002: XcodeGen 프로젝트와 무료 팀 서명](decisions/0002-project-generation-and-signing.md)

## 빠른 상태

- 제품: iOS 26+ iPhone용 운동 루틴·세트·휴식 타이머 앱
- 핵심 위험: 앱과 잠금 화면의 세션 불일치, 실제 시각과 타이머 불일치,
  백그라운드 오디오/알림 정책, 저장 실패 뒤 낙관적 UI 전환
- 로컬 기본 게이트: `swift test`, `swift run DamSetCoreSmoke`,
  `ruby Scripts/check_agent_wiki.rb`, `git diff --check`
- 전체 iOS 게이트: `xcodebuild`로 앱·코어·Live Activity 타깃 빌드/테스트
- 아직 사람 관찰이 중요한 영역: 실제 잠금 화면 표시, 햅틱, 음악 위의 휴식 종료음
