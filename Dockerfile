# Slack MCP Server with Supergateway - Dockerfile
FROM supercorp/supergateway:latest

# 작업 디렉토리 설정
WORKDIR /app

# .env 파일 복사 (빌드 시점에 포함)
COPY .env ./

# 포트 노출
EXPOSE 8000

# 환경변수 설정
ENV NODE_ENV=production
ENV PORT=8000

# 헬스체크 추가
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Supergateway로 Slack MCP 서버 실행
CMD ["npx", "supergateway", \
     "--outputTransport", "sse", \
     "--stdio", "npx -y dotenv -e .env -- npx -y @modelcontextprotocol/server-slack", \
     "--port", "8000", \
     "--cors", \
     "--healthEndpoint", "/health", \
     "--logLevel", "info"]