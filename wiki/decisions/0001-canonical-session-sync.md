---
type: decision
status: active
updated: "2026-07-19"
tags: [adr, session, synchronization]
sources:
  - Sources/DamSetCore/WorkoutEngine.swift
  - Sources/DamSetCore/LiveActivitySupport.swift
  - DamSetApp/WorkoutViewModel.swift
  - DamSetLiveActivity/WorkoutIntents.swift
---

# ADR-0001: 정규 세션과 단일 동기화 파이프라인

## 상태

Accepted

## 맥락

운동 수행량은 앱 화면과 잠금 화면 양쪽에서 바뀔 수 있다. App Intent 탭은
빠르게 겹칠 수 있고, 휴식 타이머·알림·완료 저장·Live Activity가 서로 다른
순서로 갱신되면 세트가 사라지거나 오래된 화면이 새 운동을 바꿀 수 있다.

## 결정

- `WorkoutRoutineSession`과 그 안의 `lockScreenState`를 진행 중 운동의
  정규 상태로 사용한다.
- 상태 전이는 `WorkoutEngine`에서 수행한다.
- 일반 변경은 `WorkoutSessionSync.applyDidChange`의 저장 → 알림 동기화
  → Live Activity 동기화 순서를 사용한다.
- App Intent는 전체 load → mutate → save를 actor로 직렬화하고 대상
  `sessionId`가 현재 세션과 일치할 때만 변경한다.
- 빠른 수행량 보정은 의미 전이가 없을 때만 전용 correction 경로를 쓴다.
- 완료 동작은 영속 저장 성공 뒤에만 UI에 휴식/완료 상태를 공개한다.

## 결과

장점:

- 앱과 잠금 화면이 같은 실제 횟수·시간·무게를 본다.
- 빠른 탭의 stale snapshot 덮어쓰기를 줄인다.
- 저장 실패 때 사용자가 현재 세트를 다시 시도할 수 있다.
- 오래된 Live Activity가 새 운동을 오염시키지 않는다.

비용:

- 새 세션 필드나 상태 전이는 앱, 코어, Intent, Activity 표시, 저장 호환성을
  함께 검토해야 한다.
- 파이프라인을 우회하는 간단한 UI 변경도 데이터 경쟁을 만들 수 있다.
- correction 최적화와 전체 동기화의 경계를 테스트해야 한다.

## 구현 규칙

직접 스토어를 쓰거나 Live Activity만 따로 갱신하는 새 경로를 만들지 않는다.
예외가 필요하면 이 결정을 갱신하고 저장 실패, 빠른 동시 탭, 오래된
`sessionId`의 회귀 테스트를 먼저 정의한다.
