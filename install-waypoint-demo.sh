#!/bin/bash

function prompt {
  read # Wait for the user to press Enter
  local count=$#
  local i=1

  for str in "$@"; do
    if [ $i -lt $count ]; then
      echo -e "$str"
    else
      echo -n "$str"
    fi
    ((i++))
  done

  read # Wait for the user to press Enter

  echo ""
}

function execute_command {
  echo "$1"
  eval "$1"
  echo ""
}

clear

prompt "Demo of Installing Kmesh Waypoint\n" "Kmesh, Istio have been installed"

execute_command "kubectl get pods --all-namespaces"

prompt "Use Kmesh manage default namespace"

execute_command "kubectl label namespace default istio.io/dataplane-mode=Kmesh"

execute_command "kubectl get namespace -L istio.io/dataplane-mode"

prompt "Deploy bookinfo"

execute_command "kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/bookinfo/platform/kube/bookinfo.yaml"

prompt "Deploy sleep as curl client"

execute_command "kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/sleep/sleep.yaml"

execute_command "kubectl get pods"

prompt "Test bookinfo works as expected"

execute_command 'kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"'

prompt "Deploy a waypoint for reviews service"

execute_command "istioctl x waypoint apply -n default --name reviews-svc-waypoint"

execute_command "kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint"

prompt "Use kubectl get pods to see all the pods except waypoint are ready"

execute_command "kubectl get gateways.gateway.networking.k8s.io"

prompt "Replace the waypoint image with Kmesh customized image"

execute_command "kubectl annotate gateway reviews-svc-waypoint sidecar.istio.io/proxyImage=ghcr.io/kmesh-net/waypoint:latest"

prompt "Then gateway pod will restart. Now Kmesh is L7 enabled!\n" "Watch kubectl get pods"

execute_command "kubectl get pods"


prompt "Cleanup"

execute_command "istioctl x waypoint delete reviews-svc-waypoint"

execute_command "kubectl label service reviews istio.io/use-waypoint-"

execute_command "kubectl label namespace default istio.io/dataplane-mode-"

