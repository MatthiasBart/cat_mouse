FROM golang:1.22-alpine AS ai-build

WORKDIR /ai-build
COPY ./ai/ ./
RUN go build -o game-ai .

FROM swift:6.1-noble

WORKDIR /app
COPY --from=ai-build /ai-build/game-ai /app/game-ai
COPY ./server/ .

ENV AI_BINARY_PATH=/app/game-ai

EXPOSE 8080

CMD ["swift", "run", "server", "serve", "--hostname", "0.0.0.0", "--port", "8080"]
