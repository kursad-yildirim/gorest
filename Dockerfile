FROM docker.io/golang:1.20-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN go build -o moviecollection

FROM docker.io/alpine:latest
COPY --from=build /app/moviecollection /app/moviecollection
WORKDIR /app
EXPOSE 8080
CMD ["./moviecollection"]