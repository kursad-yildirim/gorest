#!/bin/bash
REGISTRY=moria.middle.earth:443
APP=moviecollection
VER=0.1
DEVELOPER=trip
IMAGE=$REGISTRY/$DEVELOPER/$APP:$VER
PORT=8080


clear

rm -R ./Dockerfile manifests/deployment.yaml manifests/service.yaml > /dev/null 2>&1
rm -R ./logs/* > /dev/null 2>&1
podman images | grep -E "none|$IMAGE" |awk '{print $3}' | xargs podman rmi -f > /dev/null 2>&1


cat <<EOF >./Dockerfile
FROM docker.io/golang:1.20-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN go build -o $APP

FROM docker.io/alpine:latest
COPY --from=build /app/$APP /app/$APP
WORKDIR /app
EXPOSE $PORT
CMD ["./$APP"]
EOF

echo "Podman build started"
podman build ./ -t $IMAGE > ./logs/podman-build.log 2>&1
if [ $? -eq 0 ] 
then
    echo "Podman build succeeded"
else
    echo "Podman build failed"
fi

echo "Podman push started"
podman push --authfile ~/.docker/moria.json $IMAGE > ./logs/podman-push.log 2>&1
if [ $? -eq 0 ] 
then
    echo "Podman push succeeded"
else
    echo "Podman push failed"
fi

cat <<EOF >manifests/deployment.yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: $APP
  namespace: $DEVELOPER
  labels:
    app: $APP
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $APP
  template:
    metadata:
       labels:
         app: $APP
    spec:
      containers:
        - name: $APP
          image: $IMAGE
          imagePullPolicy: Always
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            seccompProfile:
              type: RuntimeDefault
            capabilities:
              drop:
               - ALL
          env:
            - name: APP_PORT
              valueFrom:
                configMapKeyRef:
                  name: $APP
                  key: APP_PORT
EOF

cat <<EOF >manifests/service.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: $APP
  name: $APP
  namespace: $DEVELOPER
  annotations:
    metallb.universe.tf/address-pool: metallb-pool-239
spec:
  ports:
  - name: http
    port: $PORT
    protocol: TCP
    targetPort: $PORT
  selector:
    app: $APP
  type: LoadBalancer
EOF

cat <<EOF >manifests/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: $APP
  namespace: $DEVELOPER
data:
  APP_PORT: "$PORT"
EOF
echo "OpenShift clean up started"
oc delete -f manifests/ > ./logs/oc-delete.log 2>&1
if [ $? -eq 0 ] 
then
    echo "OpenShift clean up succeeded"
else
    echo "OpenShift clean up failed"
fi

echo "OpenShift resource creation started"
oc apply -f manifests/> ./logs/oc-create.log 2>&1
if [ $? -eq 0 ] 
then
    echo "OpenShift resource creation succeeded"
else
    echo "OpenShift resource creation failed"
fi