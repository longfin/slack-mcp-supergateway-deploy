# Slack MCP 서버 Fly.io 배포 가이드

## 📋 사전 준비

### 1. 필요한 파일들
```
프로젝트/
├── Dockerfile
├── fly.toml
├── .env (로컬 테스트용)
└── .dockerignore
```

### 2. .env 파일 예시 (로컬 테스트용)
```bash
# Slack API 토큰들
SLACK_BOT_TOKEN=xoxb-your-bot-token
SLACK_USER_TOKEN=xoxp-your-user-token  
SLACK_TEAM_ID=your-team-id

# 추가 설정 (선택사항)
SLACK_LOGGING_LEVEL=info
```

### 3. .dockerignore 파일
```
node_modules
npm-debug.log*
.git
.gitignore
README.md
.env.local
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

# 로컬 실행 (.env 파일 사용)
docker run -p 8000:8000 --env-file .env slack-mcp-server

# 브라우저에서 확인
# http://localhost:8000/sse
```

### npx로 직접 테스트
```bash
# .env 파일이 있는 디렉토리에서
npx -y supergateway \
  --outputTransport sse \
  --stdio "npx -y dotenv -e .env -- npx -y @modelcontextprotocol/server-slack" \
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

1. **절대 .env 파일을 Git에 커밋하지 마세요**
2. **모든 민감한 데이터는 flyctl secrets로 관리**
3. **HTTPS 강제 활성화 (fly.toml에서 설정됨)**
4. **적절한 CORS 설정**

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

이 설정은 다음 명령어를 기반으로 만들어졌습니다:
```bash
npx -y supergateway --outputTransport sse --stdio "npx -y dotenv -e .env -- npx -y @modelcontextprotocol/server-slack"
```

## 🔗 관련 링크

- [Supergateway GitHub](https://github.com/supercorp-ai/supergateway)
- [Fly.io 문서](https://fly.io/docs/)
- [MCP Slack 서버](https://github.com/modelcontextprotocol/servers/tree/main/src/slack)
- [MCP 공식 문서](https://modelcontextprotocol.io/)
