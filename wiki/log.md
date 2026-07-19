---
type: log
status: active
updated: "2026-07-19"
tags: [agent-wiki, work-log]
---

# 작업 로그

완료된 의미 있는 작업을 오래된 순서에서 최신 순서로 끝에 추가한다. 상세
지식은 종합 페이지와 ADR에 두고 여기에는 범위, 행동, 결정, 실제 검증만
기록한다.

## [2026-07-19] setup | 에이전트 LLM 위키 초기화

- Scope: 저장소 전역 에이전트 계약과 제품·구조·도구·검증·기기 QA·결정 페이지를 만들고 README에서 위키로 진입할 수 있게 했다.
- Actions: Karpathy의 LLM Wiki 패턴을 근거/위키/운영 3계층으로 적용하고, 현재 코드·문서·Git 이력에서 초기 지식을 종합했다. 상대 링크와 frontmatter를 검사하는 로컬 lint를 추가했다.
- Decisions: 코드·테스트·설정·실행 결과를 원본 근거로 유지하고 별도 raw 복제는 만들지 않는다. 모든 의미 있는 작업은 전·중·후 위키 루프와 append-only 완료 로그를 따른다.
- Verification: `ruby Scripts/check_agent_wiki.rb` 통과(11 pages), `ruby -c Scripts/check_agent_wiki.rb` 통과, `git diff --check` 통과.
- Wiki: `wiki/index.md`, `wiki/schema.md`, `wiki/product.md`, `wiki/architecture.md`, `wiki/tools.md`, `wiki/playbooks/`, `wiki/decisions/`

## [2026-07-19] docs | 실기기 화면 기반 README 히어로 교체

- Scope: 연결된 iPhone의 실제 DamSet 루틴·준비·운동·휴식 화면을 확인하고 `docs/assets/damset-hero.jpg`를 현재 휴식 UI 기반 이미지로 교체했다.
- Actions: iPhone Mirroring을 Computer Use로 조작해 실제 화면을 캡처하고 캡처용 운동은 저장하지 않고 폐기했다. 기존 히어로를 구도·분위기 참조로, 실제 휴식 화면을 UI 참조로 사용해 built-in image generation으로 합성한 뒤 JPEG로 변환했다.
- Decisions: 바벨 중심의 어두운 체육관 구도는 유지하고, 허구의 녹색 원형 대시보드 대신 실제 검정 금속 패널·적색 `01:30` 휴식 화면과 적색 실내 조명을 사용한다.
- Verification: 실기기에서 원본 UI 관찰, 최종 이미지 육안 확인, JPEG `1672×941` 확인, `ruby Scripts/check_agent_wiki.rb`와 `git diff --check` 통과.
- Wiki: `wiki/product.md`, `wiki/tools.md`, `wiki/playbooks/device-live-activity.md`
