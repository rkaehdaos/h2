# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

이 프로젝트는 Alpine Linux 기반의 경량 H2 Database Docker 이미지를 제공합니다.
- 최소 크기 (~66MB)
- 멀티 아키텍처 지원 (amd64, arm64, ppc64le, s390x, 386, arm/v7, arm/v6)
- GitHub Actions를 통한 자동 빌드 및 Docker Hub 배포
- 현재 H2 버전: 2.3.232

## 핵심 아키텍처

### Docker 이미지 구조
- **베이스 이미지**: `openjdk:jre-alpine`
- **데이터 디렉토리**: `/opt/h2-data` (볼륨 마운트 포인트)
- **포트**:
  - `1521`: TCP 데이터베이스 연결 포트
  - `81`: 웹 콘솔 포트
- **H2 서버 설정**: `h2.server.properties` 파일이 `/root/.h2.server.properties`에 복사됨

### 빌드 시스템
- Docker Buildx를 사용한 멀티 플랫폼 빌드
- GitHub Actions에서 `H2VERSION`과 `H2RELEASEDATE` secrets를 통해 버전 관리
- 빌드 캐시 최적화 (5GB 제한)

## 주요 명령어

### 로컬 개발 및 테스트

**Docker 이미지 로컬 빌드:**
```bash
# 단일 플랫폼 빌드 (테스트용)
docker build -t rkaehdaos/h2:test \
  --build-arg H2_VERSION=2.3.232 \
  --build-arg H2_RELEASEDATE=2024-08-11 \
  .

# 멀티 플랫폼 빌드 (프로덕션)
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/ppc64le,linux/s390x,linux/386,linux/arm/v7,linux/arm/v6 \
  --build-arg H2_VERSION=2.3.232 \
  --build-arg H2_RELEASEDATE=2024-08-11 \
  -t rkaehdaos/h2:latest \
  --load .
```

**컨테이너 실행:**
```bash
# 기본 실행 (example-run.sh 참고)
docker run -d \
  -v $PWD/h2-data:/opt/h2-data \
  -p 1521:1521 -p 81:81 \
  --name=my-h2 \
  rkaehdaos/h2

# DB 자동 생성 옵션 포함 (example-run-with-make-new-db.sh 참고)
docker run -d \
  -e H2_OPTIONS='-ifNotExists' \
  -v $PWD/h2-data:/opt/h2-data \
  -p 1521:1521 -p 81:81 \
  --name=my-h2 \
  rkaehdaos/h2
```

**컨테이너 관리:**
```bash
# 로그 확인
docker logs -f my-h2

# 컨테이너 중지 및 삭제 (example-stop.sh 참고)
docker stop my-h2
docker rm my-h2
```

**웹 콘솔 접속:**
- URL: `http://localhost:81`
- 기본 연결 설정 (h2.server.properties 참고):
  - Embedded: `jdbc:h2:test`
  - Server: `jdbc:h2:tcp://localhost:1521/test`
  - 사용자: `sa`

### CI/CD

**GitHub Actions 워크플로우:**
- `main` 브랜치에 push하면 자동으로 빌드 및 배포
- Repository Secrets 필요:
  - `DOCKERHUB_USERNAME`: Docker Hub 사용자명
  - `DOCKERHUB_TOKEN`: Docker Hub 액세스 토큰
  - `H2VERSION`: H2 데이터베이스 버전 (예: 2.3.232)
  - `H2RELEASEDATE`: H2 릴리스 날짜 (예: 2024-08-11)
  - `SLACK_WEBHOOK_URL`: (선택) 빌드 알림용 Slack webhook

**버전 업그레이드 절차:**
1. GitHub Repository Secrets에서 `H2VERSION`과 `H2RELEASEDATE` 업데이트
2. `README.md`의 Release Note 섹션에 새 버전 추가
3. `main` 브랜치에 커밋 및 push
4. GitHub Actions가 자동으로 빌드 및 Docker Hub에 배포

## 환경 변수

- `H2_OPTIONS`: H2 서버 실행 시 추가 옵션 (예: `-ifNotExists`)
- `DATA_DIR`: 데이터 디렉토리 경로 (기본값: `/opt/h2-data`)

## 주의사항

### Docker Buildx 설정
- 멀티 플랫폼 빌드를 위해 QEMU와 BuildX 설정 필요
- 로컬에서 테스트 시 `--load` 플래그는 단일 플랫폼에서만 작동
- 멀티 플랫폼 빌드 시 `--push` 플래그 사용 또는 로컬 레지스트리 활용

### H2 버전 관리
- H2 Database 다운로드 URL 패턴: `https://github.com/h2database/h2database/releases/download/version-{VERSION}/h2-{RELEASEDATE}.zip`
- 버전 업그레이드 시 `H2_VERSION`과 `H2_RELEASEDATE`를 정확히 매칭해야 함
- Dockerfile의 ARG 값은 빌드 시 반드시 전달되어야 함

### 데이터 영속성
- 프로덕션 환경에서는 반드시 `-v` 옵션으로 로컬 디렉토리를 `/opt/h2-data`에 마운트
- 컨테이너 삭제 시 마운트되지 않은 데이터는 소실됨
