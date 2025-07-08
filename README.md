# Slack MCP 서버 Fly.io 배포 가이드

## 📋 사전 준비

### 1. 필요한 파일들
```
프로젝트/
├── Dockerfile
├── fly.toml
└── .dockerignore
```

### 2. Slack API 토큰 준비
다음 토큰들이 필요합니다:
- `SLACK_BOT_TOKEN`: xoxb-로 시작하는 봇 토큰
- `SLACK_USER_TOKEN`: xoxp-로 시작하는 사용자 토큰  
- `SLACK_TEAM_ID`: Slack 팀/워크스페이스 ID

### 3. .dockerignore 파일
```
node_modules
npm-debug.log*
.git
.gitignore
README.md
.env*
.nyc_output
coverage
.vscode
```

## 🚀 배포 단계

### 1. Fly.io 앱 생성
```bash
# Fly.io CLI 설치 확인
flyctl version

# 앱 생성 (fly.toml이 있으면 자동 감지)
flyctl apps create slack-mcp-server
```

### 2. 환경변수(Secrets) 설정
```bash
# Slack 토큰들을 secrets로 설정
flyctl secrets set SLACK_BOT_TOKEN=xoxb-your-actual-bot-token
flyctl secrets set SLACK_USER_TOKEN=xoxp-your-actual-user-token
flyctl secrets set SLACK_TEAM_ID=your-actual-team-id

# 설정된 secrets 확인
flyctl secrets list
```

### 3. 배포 실행
```bash
# 첫 배포
flyctl deploy

# 배포 상태 확인
flyctl status
```

### 4. 배포 후 테스트
```bash
# 로그 확인
flyctl logs

# 앱 URL 확인 
flyctl info

# SSE 엔드포인트 테스트
curl https://slack-mcp-server.fly.dev/sse

# 헬스체크 확인
curl https://slack-mcp-server.fly.dev/health
```

## 🔧 로컬 테스트

### Docker로 로컬 테스트
```bash
# 이미지 빌드
docker build -t slack-mcp-server .

# 환경변수와 함께 로컬 실행
docker run -p 8000:8000 \
  -e SLACK_BOT_TOKEN=xoxb-your-bot-token \
  -e SLACK_USER_TOKEN=xoxp-your-user-token \
  -e SLACK_TEAM_ID=your-team-id \
  slack-mcp-server

# 브라우저에서 확인
# http://localhost:8000/sse
```

### npx로 직접 테스트
```bash
# 환경변수 설정 후 실행
export SLACK_BOT_TOKEN=xoxb-your-bot-token
export SLACK_USER_TOKEN=xoxp-your-user-token
export SLACK_TEAM_ID=your-team-id

npx -y supergateway \
  --outputTransport sse \
  --stdio "npx -y @modelcontextprotocol/server-slack" \
  --port 8000 \
  --cors \
  --healthEndpoint /health
```

## 📊 MCP Inspector로 테스트
```bash
# MCP Inspector 실행
npx @modelcontextprotocol/inspector --uri https://slack-mcp-server.fly.dev/sse

# 또는 로컬 테스트
npx @modelcontextprotocol/inspector --uri http://localhost:8000/sse
```

## 🔌 클라이언트 연결 설정

### Claude Desktop 설정
```json
{
  "mcpServers": {
    "slack-remote": {
      "command": "npx",
      "args": [
        "mcp-remote", 
        "https://slack-mcp-server.fly.dev/sse"
      ]
    }
  }
}
```

### 직접 SSE 연결 (지원하는 클라이언트)
```json
{
  "mcpServers": {
    "slack-direct": {
      "type": "sse",
      "url": "https://slack-mcp-server.fly.dev/sse"
    }
  }
}
```

## 🛠 트러블슈팅

### 1. 배포 실패
```bash
# 로그 확인
flyctl logs --app slack-mcp-server

# 머신 상태 확인
flyctl status
```

### 2. 환경변수 문제
```bash
# Secrets 재설정
flyctl secrets unset SLACK_BOT_TOKEN
flyctl secrets set SLACK_BOT_TOKEN=new-token

# 앱 재시작
flyctl machine restart
```

### 3. 연결 문제
```bash
# 헬스체크 확인
curl -v https://slack-mcp-server.fly.dev/health

# SSE 스트림 테스트
curl -H "Accept: text/event-stream" https://slack-mcp-server.fly.dev/sse
```

## 📈 스케일링 및 최적화

### 리소스 조정
```bash
# 메모리 증가
flyctl scale memory 1024

# CPU 증가
flyctl scale count 2
```

### 모니터링
```bash
# 실시간 로그
flyctl logs -f

# 메트릭 확인
flyctl status --all
```

## 💡 보안 고려사항

1. **모든 민감한 데이터는 flyctl secrets로 관리**
2. **HTTPS 강제 활성화 (fly.toml에서 설정됨)**
3. **적절한 CORS 설정**
4. **환경변수는 컨테이너 런타임에서 자동 주입**

## 🔄 업데이트 및 유지보수

### 앱 업데이트
```bash
# 코드 변경 후 재배포
flyctl deploy

# 롤백 (필요시)
flyctl releases list
flyctl releases rollback <version>
```

## 📝 원본 명령어

이 설정은 다음 명령어를 간소화한 버전입니다:
```bash
# 원본 (로컬용)
npx -y supergateway --outputTransport sse --stdio "npx -y dotenv -e .env -- npx -y @modelcontextprotocol/server-slack"

# 배포용 (환경변수 자동 주입)
npx -y supergateway --outputTransport sse --stdio "npx -y @modelcontextprotocol/server-slack"
```

## 🔗 관련 링크

- [Supergateway GitHub](https://github.com/supercorp-ai/supergateway)
- [Fly.io 문서](https://fly.io/docs/)
- [MCP Slack 서버](https://github.com/modelcontextprotocol/servers/tree/main/src/slack)
- [MCP 공식 문서](https://modelcontextprotocol.io/)
