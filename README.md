# OcellusAI Helm Chart

A Helm chart for OcellusAI Operator - manages serverless AI monitoring service deployments.

## Installation

Install from local directory:

```bash
helm upgrade -i ocellusai ./helm/ocellusai -f values.yaml -n monitoring --create-namespace
```

## Configuration

See [values.yaml](values.yaml) for all available configuration options.

### Key Configuration Parameters

#### Operator
- `operator.image.repository` - Operator image repository
- `operator.image.tag` - Operator image tag
- `operator.resources` - Resource requests/limits
- `operator.serviceAccount.create` - Create ServiceAccount (default: true)
- `operator.rbac.create` - Create RBAC resources (default: true)

#### Web Service
- `service.enabled` - Enable web service deployment (default: true)
- `service.image.repository` - Service image repository
- `service.image.tag` - Service image tag
- `service.replicas` - Number of replicas
- `service.port` - Service port (default: 8080)
- `service.resources` - Resource requests/limits
- `service.modelName` - AI model name
- `service.baseUrl` - AI service base URL
- `service.apiKey` - API key for authentication
- `service.metricServerUrl` - Prometheus server URL for metrics collection
- `service.jobName` - Job name for metrics identification
- `service.costPerCPU` - Cost per CPU unit (default: 0.031)
- `service.costPerMEM` - Cost per memory unit (default: 0.004)
- `service.ingress.enabled` - Enable ingress
- `service.ingress.host` - Ingress hostname

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
  -n monitoring
```

## Uninstallation

```bash
helm uninstall ocellusai -n monitoring
```