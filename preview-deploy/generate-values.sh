#!/bin/bash

# services
services=(
  "config-server"
  "discovery-server"
  "customers-service"
  "visits-service"
  "vets-service"
  "genai-service"
  "api-gateway"
  "admin-server"
)

account="championvi12"

# get port of service
get_port() {
  case "$1" in
    config-server) echo 8888 ;;
    discovery-server) echo 8761 ;;
    customers-service) echo 8081 ;;
    visits-service) echo 8082 ;;
    vets-service) echo 8083 ;;
    genai-service) echo 8084 ;;
    api-gateway) echo 8080 ;;
    admin-server) echo 9090 ;;
    *) echo 0 ;;  
  esac
}

# create values.yaml for each service
for svc in "${services[@]}"; do
  dir="values/${svc}"
  mkdir -p "$dir"

  port=$(get_port "$svc")

  cat <<EOF > "${dir}/values.yaml"
services:
  ${svc}:
    enabled: true
    image: "${account}/spring-petclinic-${svc}"
    tag: "latest"
    port: ${port}
EOF

  echo "✅ Created $dir/values.yaml with image: spring-petclinic-${svc} and port: ${port}"
done
