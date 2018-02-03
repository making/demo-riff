#!/bin/bash

helm install riffrepo/riff --name demo \
     --version 0.0.3-rbac \
     --set httpGateway.service.type=NodePort

