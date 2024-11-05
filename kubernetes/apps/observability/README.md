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
 
## [Gatus](gatus/README.md)

Live Status Dashboard for keeping track of uptimes.

## [Goldilocks](goldilocks/README.md)

Get your resource requests "Just Right". Keeps an eye on metrics for suggesting Kubernete Resource Limits and Requests.

## [Grafana](grafana/README.md)

Provides dashboards. Queries from Prometheus (or Thanos)

## [Karma](karma/README.md)

Alert dashboard for Prometheus Alertmanager.

## [Kromgo](kromgo/README.md)

Exposes preconfigured prometheus metrics to the outside using badges.

## [Prometheus](kube-prometheus-stack/README.md)

Time-series database for metrics.
Exporters / serviceMonitors ship metrics to Prometheus.

## Alertmanager

Alertmanager handles alerts sent by client applications such as the Prometheus server.
It takes care of deduplicating, grouping, and routing them to the correct receiver integration such as email, PagerDuty, or OpsGenie.

## Loki

Like Prometheus, but for logs.

## Promtail

Agent responsible for gathering and sending logs to Loki

## Thanos

Highly available Prometheus setup with long term storage capabilities.

