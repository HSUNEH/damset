---
type: decision
status: active
updated: "2026-07-19"
tags: [adr, xcodegen, signing, live-activity]
sources:
  - project.yml
  - DamSet.xcodeproj/project.pbxproj
  - docs/install.md
  - Sources/DamSetCore/LiveActivitySupport.swift
---

# ADR-0002: XcodeGen 프로젝트와 무료 팀 서명

## 상태

Accepted

## 맥락

DamSet은 앱, 코어 프레임워크, Live Activity 확장을 함께 빌드한다. 생성된
Xcode 프로젝트를 수동으로 고치면 선언 원본과 쉽게 어긋난다. 또한 무료 Apple
개발 팀은 App Group capability를 만들 수 없지만 실기기에서 전체 Live
Activity 흐름은 계속 검증해야 한다.

## 결정

- `project.yml`을 Xcode 타깃·빌드 설정의 선언 원본으로 사용하고
  `DamSet.xcodeproj`는 XcodeGen으로 재생성한다.
- 프로젝트 설정 변경 뒤 `~/.local/bin/xcodegen generate`를 실행하고 생성
  diff와 전체 iOS 빌드를 확인한다.
- 현재 무료 팀 구성에서는 앱과 확장 양쪽의 App Group entitlement를 두지
  않는다.
- Live Activity Intent를 앱 타깃에도 컴파일해 앱 프로세스에서 정규 세션
  파이프라인을 사용하게 한다.
- 저장소는 공유 컨테이너를 쓸 수 없을 때 앱 로컬 컨테이너로 폴백한다.

## 결과

장점:

- 프로젝트 구조를 재현 가능하게 유지한다.
- 유료 capability 없이 앱과 Live Activity를 실기기에 설치할 수 있다.
- Intent가 앱과 같은 mutation gate와 저장 경로를 사용한다.

제약:

- 무료 팀 프로파일 만료 뒤 다시 설치해야 한다.
- App Group이 없으므로 데이터는 앱 로컬 컨테이너에 남는다.
- 유료 팀으로 전환해 App Group을 복원할 때는 entitlements, 컨테이너
  마이그레이션, 앱/확장 접근 방식을 다시 검증해야 한다.

## 변경 조건

유료 개발 팀 또는 클라우드/공유 저장 요구가 생길 때 대체 ADR을 작성한다.
그 전에는 서명 문제를 피하기 위해 확장을 제거하거나 entitlement를 임의로
복원하지 않는다.
