#!/bin/bash

# Скрипт для очистки застрявших OcellusAI ресурсов
# Использование: ./cleanup-stuck-resources.sh [namespace] [resource-name]

NAMESPACE="${1:-monitoring}"
RESOURCE_NAME="${2:-}"

echo "🧹 OcellusAI Cleanup Script"
echo "=========================="
echo ""

# Если имя ресурса не указано, найдем все ресурсы
if [ -z "$RESOURCE_NAME" ]; then
    echo "📋 Searching for all OcellusAI resources in namespace: $NAMESPACE"
    RESOURCES=$(kubectl get ocellusai.ocellusai.com -n $NAMESPACE -o name 2>/dev/null | cut -d'/' -f2)
    
    if [ -z "$RESOURCES" ]; then
        echo "ℹ️  No OcellusAI resources found in namespace $NAMESPACE"
        exit 0
    fi
    
    echo "Found resources:"
    echo "$RESOURCES"
    echo ""
else
    RESOURCES="$RESOURCE_NAME"
fi

# Обрабатываем каждый ресурс
for RESOURCE in $RESOURCES; do
    echo "🔧 Processing resource: $RESOURCE"
    echo "--------------------------------"
    
    # Проверяем существует ли ресурс
    if ! kubectl get ocellusai.ocellusai.com $RESOURCE -n $NAMESPACE >/dev/null 2>&1; then
        echo "⚠️  Resource $RESOURCE not found, skipping..."
        echo ""
        continue
    fi
    
    # Показываем текущий статус
    echo "📊 Current status:"
    kubectl get ocellusai.ocellusai.com $RESOURCE -n $NAMESPACE -o yaml | grep -A5 "metadata:"
    
    # Удаляем финализеры
    echo ""
    echo "🗑️  Removing finalizers..."
    kubectl patch ocellusai.ocellusai.com $RESOURCE -n $NAMESPACE \
        --type json \
        -p='[{"op": "remove", "path": "/metadata/finalizers"}]' 2>/dev/null || echo "⚠️  No finalizers to remove or already removed"
    
    # Удаляем Deployment если существует
    echo ""
    if kubectl get deployment ${RESOURCE}-deployment -n $NAMESPACE >/dev/null 2>&1; then
        echo "🗑️  Deleting deployment: ${RESOURCE}-deployment"
        kubectl delete deployment ${RESOURCE}-deployment -n $NAMESPACE \
            --grace-period=0 --force 2>/dev/null || echo "⚠️  Failed to delete deployment"
        echo "✅ Deployment deleted"
    else
        echo "ℹ️  No deployment found for $RESOURCE"
    fi
    
    # Удаляем CronJob если существует
    echo ""
    if kubectl get cronjob ${RESOURCE}-cronjob -n $NAMESPACE >/dev/null 2>&1; then
        echo "🗑️  Deleting cronjob: ${RESOURCE}-cronjob"
        kubectl delete cronjob ${RESOURCE}-cronjob -n $NAMESPACE \
            --grace-period=0 --force 2>/dev/null || echo "⚠️  Failed to delete cronjob"
        echo "✅ CronJob deleted"
    else
        echo "ℹ️  No cronjob found for $RESOURCE"
    fi
    
    # Удаляем Jobs если существуют
    echo ""
    JOBS=$(kubectl get jobs -n $NAMESPACE -l app=${RESOURCE} -o name 2>/dev/null)
    if [ ! -z "$JOBS" ]; then
        echo "🗑️  Deleting jobs:"
        echo "$JOBS"
        kubectl delete jobs -n $NAMESPACE -l app=${RESOURCE} \
            --grace-period=0 --force 2>/dev/null || echo "⚠️  Failed to delete some jobs"
        echo "✅ Jobs deleted"
    else
        echo "ℹ️  No jobs found for $RESOURCE"
    fi
    
    # Удаляем CR
    echo ""
    echo "🗑️  Deleting custom resource: $RESOURCE"
    kubectl delete ocellusai.ocellusai.com $RESOURCE -n $NAMESPACE \
        --grace-period=0 --force 2>/dev/null || echo "⚠️  Failed to delete CR (might be already deleted)"
    
    echo ""
    echo "✅ Cleanup completed for: $RESOURCE"
    echo ""
done

# Финальная проверка
echo ""
echo "🔍 Final verification..."
echo "========================"
echo ""

echo "📋 Remaining OcellusAI resources:"
kubectl get ocellusai.ocellusai.com -n $NAMESPACE 2>/dev/null || echo "None"

echo ""
echo "📋 Remaining deployments:"
kubectl get deployment -n $NAMESPACE 2>/dev/null | grep -E "NAME|ocellusai" || echo "None"

echo ""
echo "📋 Remaining pods:"
kubectl get pods -n $NAMESPACE 2>/dev/null | grep -E "NAME|ocellusai" || echo "None"

echo ""
echo "✨ Cleanup script finished!"
