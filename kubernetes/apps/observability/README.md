# Monitoring and Observability

- [Monitoring and Observability](#monitoring-and-observability)
  - [Gatus](#gatus)
  - [Goldilocks](#goldilocks) 
  - [Grafana](#grafana)
  - [Karma](#karma)
  - [Kromgo](#kromgo)
  - Kube-Prometheus-Stack
    - [Prometheus](#prometheus)
    - [Alertmanager](#alertmanager)
  - [Loki](#loki)
  - [Thanos](#thanos)
  - [Vector](#vector)
 
## Gatus

Live Status Dashboard for keeping track of uptimes.

## Goldilocks

Get your resource requests "Just Right". Keeps an eye on metrics for suggesting Kubernete Resource Limits and Requests.

## Grafana

Provides dashboards. Queries from Prometheus (or Thanos)

## Karma

Alert dashboard for Prometheus Alertmanager.

## Kromgo

Exposes preconfigured prometheus metrics to the outside using badges.

## Prometheus

Time-series database for metrics.
Exporters / serviceMonitors ship metrics to Prometheus.

## Alertmanager

Alertmanager handles alerts sent by client applications such as the Prometheus server.
It takes care of deduplicating, grouping, and routing them to the correct receiver integration such as email, PagerDuty, or OpsGenie.

## Loki

Like Prometheus, but for logs.

## Thanos

Highly available Prometheus setup with long term storage capabilities.

## Vector

Log Aggregator. **TO BE REPLACED by Promtail**

