# Инструкция по устранению проблемы с застрявшим CR

## Проблема
При удалении Helm чарта custom resource `ocellusai.ocellusai.com` остается в системе с финализером `kopf.zalando.org/KopfFinalizerMarker`, что блокирует удаление Deployment.

## Причина
Когда удаляется Helm чарт, оператор удаляется раньше, чем CR, и финализер Kopf не может быть обработан.

## Текущее решение для застрявшего ресурса

### Вариант 1: Удаление финализера вручную (быстро)

```bash
# Удаляем финализер с CR
kubectl patch ocellusai.ocellusai.com ocellusai-service -n monitoring \
  --type json \
  -p='[{"op": "remove", "path": "/metadata/finalizers"}]'

# Проверяем что ресурс удален
kubectl get ocellusai.ocellusai.com -n monitoring

# Проверяем что deployment тоже удален
kubectl get deployment -n monitoring | grep ocellusai
```

### Вариант 2: Принудительное удаление

```bash
# Удаляем Deployment принудительно
kubectl delete deployment ocellusai-service-deployment -n monitoring --grace-period=0 --force

# Удаляем CR принудительно
kubectl delete ocellusai.ocellusai.com ocellusai-service -n monitoring --grace-period=0 --force

# Если CR все еще висит, удаляем финализер
kubectl patch ocellusai.ocellusai.com ocellusai-service -n monitoring \
  --type json \
  -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
```

### Вариант 3: Скрипт для очистки

```bash
#!/bin/bash
NAMESPACE="monitoring"
RESOURCE_NAME="ocellusai-service"

echo "Cleaning up stuck OcellusAI resource: $RESOURCE_NAME in namespace $NAMESPACE"

# Удаляем финализер
kubectl patch ocellusai.ocellusai.com $RESOURCE_NAME -n $NAMESPACE \
  --type json \
  -p='[{"op": "remove", "path": "/metadata/finalizers"}]' 2>/dev/null || true

# Удаляем Deployment если существует
kubectl delete deployment ${RESOURCE_NAME}-deployment -n $NAMESPACE \
  --grace-period=0 --force 2>/dev/null || true

# Удаляем CR
kubectl delete ocellusai.ocellusai.com $RESOURCE_NAME -n $NAMESPACE \
  --grace-period=0 --force 2>/dev/null || true

echo "Cleanup completed!"
```

## Долгосрочное решение (реализовано)

### 1. Pre-delete Hook
Создан файл `templates/pre-delete-hook.yaml` который:
- Запускается **перед** удалением чарта (`helm.sh/hook: pre-delete`)
- Удаляет все финализеры с CR
- Удаляет все Deployments/CronJobs
- Удаляет все CR
- Ждет завершения очистки

### 2. Улучшенный оператор
В `operator/operator.py`:
- Добавлен параметр `optional=True` к обработчику удаления
- Улучшена обработка ошибок
- Добавлено логирование завершения очистки

### 3. Аннотация на CRD
В `crds/crd.yaml` добавлена аннотация:
```yaml
annotations:
  "helm.sh/resource-policy": keep
```
Это сохраняет CRD при удалении чарта, но pre-delete hook очищает все CR.

## Тестирование решения

### 1. Обновите чарт
```bash
# Соберите новый образ оператора с исправленным кодом
docker build -t your-registry/ocellusai-operator:v0.2.0 ./operator

# Обновите values.yaml с новым тегом
# operator.image.tag: v0.2.0

# Обновите чарт
helm upgrade ocellusai . -n monitoring
```

### 2. Протестируйте удаление
```bash
# Удалите чарт
helm uninstall ocellusai -n monitoring

# Проверьте что все CR удалены
kubectl get ocellusai.ocellusai.com -n monitoring

# Проверьте что deployments удалены
kubectl get deployment -n monitoring | grep ocellusai

# Проверьте логи pre-delete hook
kubectl logs -n monitoring job/ocellusai-cleanup
```

## Порядок удаления при использовании новой версии

1. Helm запускает pre-delete hook
2. Hook удаляет финализеры со всех CR
3. Hook удаляет все Deployments/CronJobs
4. Hook удаляет все CR
5. Hook ждет завершения удаления
6. Helm удаляет остальные ресурсы чарта
7. CRD остается в кластере (из-за аннотации `keep`)

## Проверка что все работает

```bash
# Установите чарт
helm install ocellusai . -n monitoring

# Проверьте что CR создался
kubectl get ocellusai.ocellusai.com -n monitoring

# Удалите чарт
helm uninstall ocellusai -n monitoring

# Должно быть пусто
kubectl get ocellusai.ocellusai.com -n monitoring
kubectl get deployment -n monitoring | grep ocellusai
kubectl get pods -n monitoring | grep ocellusai
```
