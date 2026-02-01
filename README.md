# OcellusAI-mini Helm Chart

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/ocellusai)](https://artifacthub.io/packages/search?repo=ocellusai)
![License](https://img.shields.io/badge/License-Proprietary-red)
![Release Charts](https://github.com/ocellus-ai/helm-charts/actions/workflows/release.yml/badge.svg)
![Downloads](https://img.shields.io/github/downloads/ocellus-ai/helm-charts/total?label=downloads)

A Helm chart for OcellusAI Operator - manages serverless AI monitoring service deployments.

## Installation

For detailed information on how to use OcellusAI Mini, please visit our [official website](https://ocellusai.com/docs/helm).

Or install from local directory:

```bash
helm repo add ocellusai https://ocellus-ai.github.io/helm-charts
```

## Configuration

See [values.yaml](values.yaml) for all available configuration options.

### Key Configuration Parameters

#### Web Service
- `service.modelName` - AI model name
- `service.baseUrl` - AI service base URL
- `service.apiKey` - API key for authentication
- `service.metricServerUrl` - Prometheus server URL for metrics collection
- `service.jobName` - Job name for metrics identification
- `service.costPerCPU` - Cost per CPU unit (default: 0.031)
- `service.costPerMEM` - Cost per memory unit (default: 0.004)

## Examples

### Minimal installation

```bash
helm upgrade -i ocellusai ./helm/ocellusai \
  --set service.apiKey="your-api-key" \
  --set service.modelName="gpt-4.1" \
  --set service.baseUrl="https://your-ai-service.com/v1/" \
  --set service.metricServerUrl="http://prometheus-server.monitoring.svc.cluster.local" \
  --set service.jobName="ocellusai" \
  -n monitoring
```

### With ingress enabled

```bash
helm upgrade -i ocellusai ./helm/ocellusai \
  --set service.enabled=true \
  --set service.ingress.enabled=true \
  --set service.ingress.host="ocellusai.example.com" \
  --set service.apiKey="your-api-key" \
  --set service.modelName="gpt-4.1" \
  --set service.baseUrl="https://your-ai-service.com/v1/" \
  --set service.metricServerUrl="http://prometheus-server.monitoring.svc.cluster.local" \
  --set service.jobName="ocellusai" \
  -n monitoring
```

## Uninstallation

```bash
helm uninstall ocellusai -n monitoring
```