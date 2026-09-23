#!/usr/bin/env python3
"""Convert PrometheusRule alerting rules into Grafana alert-rule provisioning.

Reads `kubectl get prometheusrules -A -o json` on stdin and prints one JSON
object per line: {"file": <name>.yaml, "doc": <provisioning document>}.
scripts/grafana-alert-rules.sh turns those into YAML files.

The output mirrors what Grafana's own Prometheus conversion
(/api/convert/prometheus/config/v1/rules) produces: an instant query
evaluated one minute behind (Grafana's default query offset for converted
rules), a math step and a threshold, with noData/execErr states OK so rules
behave like Prometheus. Recording rules are left to Prometheus.
"""

import json
import sys
import uuid

# Rule groups are filed into folders by name; anything unlisted lands in
# DEFAULT_FOLDER. Folders only organise the UI: no route matches on them.
FOLDERS = {
    "Kubernetes": [
        "kube-apiserver-slos",
        "kube-state-metrics",
        "kubernetes-apps",
        "kubernetes-resources",
        "kubernetes-storage",
        "kubernetes-system",
        "kubernetes-system-apiserver",
        "kubernetes-system-controller-manager",
        "kubernetes-system-kubelet",
        "kubernetes-system-scheduler",
    ],
    "Nodes": ["etcd", "node-exporter", "node-network", "oom"],
    "Monitoring": [
        "config-reloaders",
        "gatus.rules",
        "general.rules",
        "prometheus",
        "prometheus-operator",
    ],
    "Platform": [
        "cert-manager.rules",
        "crunchy-postgres.backups",
        "external-dns.rules",
        "flux.rules",
        "renovate-operator.rules",
    ],
}
FOLDER_BY_GROUP = {group: folder for folder, groups in FOLDERS.items() for group in groups}
DEFAULT_FOLDER = "Other"
DATASOURCE_UID = "prometheus"
# Stable rule UIDs: uuid5 of source/group/index/alert under this namespace.
UID_NAMESPACE = uuid.UUID("5d0c1f5e-4f7a-4c1e-9a55-3a7f2f0e6b21")

# PrometheusRule objects that are not migrated.
SKIP_SOURCES = {
    # Monitors Alertmanager itself, which Grafana alerting replaces.
    "observability/kps-alertmanager.rules",
}
# Individual alerts that are not migrated.
SKIP_ALERTS = {
    # Exists only to drive Alertmanager inhibition and reads the ALERTS
    # series, which goes away when Prometheus stops evaluating alerts.
    "InfoInhibitor",
}
# Alerts that notify even while the shadow label is applied.
UNSHADOWED_ALERTS = {
    # Pings Grafana's own healthchecks.io check, proving the pipeline works.
    "Watchdog",
}


def patch_annotations(alert, annotations):
    if alert == "PrometheusRemoteWriteDesiredShards":
        # Grafana templates have no `query` function.
        desc = annotations.get("description", "")
        cut = desc.find(", which is more than the max of")
        if cut != -1:
            annotations["description"] = desc[:cut] + ", which is more than the configured maximum."
    return annotations


def expr_step(ref_id, model):
    return {
        "refId": ref_id,
        "queryType": model["type"],
        "datasourceUid": "__expr__",
        "model": {"refId": ref_id, **model},
    }


def convert_rule(rule, uid, shadow):
    labels = dict(rule.get("labels") or {})
    labels["__converted_prometheus_rule__"] = "true"
    if shadow and rule["alert"] not in UNSHADOWED_ALERTS:
        labels["grafana_shadow"] = "true"
    out = {
        "uid": uid,
        "title": rule["alert"],
        "condition": "threshold",
        "data": [
            {
                "refId": "query",
                "queryType": "prometheus",
                "relativeTimeRange": {"from": 660, "to": 60},
                "datasourceUid": DATASOURCE_UID,
                "model": {
                    "refId": "query",
                    "datasource": {"type": "prometheus", "uid": DATASOURCE_UID},
                    "expr": rule["expr"].strip(),
                    "instant": True,
                    "range": False,
                    "intervalMs": 1000,
                    "maxDataPoints": 43200,
                },
            },
            expr_step("prometheus_math", {
                "type": "math",
                "expression": "is_number($query) || is_nan($query) || is_inf($query)",
            }),
            expr_step("threshold", {
                "type": "threshold",
                "expression": "prometheus_math",
                "conditions": [{"evaluator": {"type": "gt", "params": [0]}}],
            }),
        ],
        "noDataState": "OK",
        "execErrState": "OK",
    }
    if rule.get("for"):
        out["for"] = rule["for"]
    out["annotations"] = patch_annotations(rule["alert"], dict(rule.get("annotations") or {}))
    out["labels"] = labels
    out["isPaused"] = False
    out["missing_series_evals_to_resolve"] = 1
    return out


def main():
    shadow = "--shadow" in sys.argv[1:]
    items = json.load(sys.stdin)["items"]
    for item in sorted(items, key=lambda i: (i["metadata"]["namespace"], i["metadata"]["name"])):
        source = f'{item["metadata"]["namespace"]}/{item["metadata"]["name"]}'
        if source in SKIP_SOURCES:
            continue
        groups = []
        for group in item["spec"].get("groups", []):
            rules = []
            for index, rule in enumerate(group.get("rules", [])):
                if "alert" not in rule or rule["alert"] in SKIP_ALERTS:
                    continue
                uid = str(uuid.uuid5(UID_NAMESPACE, f'{source}/{group["name"]}/{index}/{rule["alert"]}'))
                rules.append(convert_rule(rule, uid, shadow))
            if rules:
                groups.append({
                    "orgId": 1,
                    "name": group["name"],
                    "folder": FOLDER_BY_GROUP.get(group["name"], DEFAULT_FOLDER),
                    "interval": group.get("interval", "30s"),
                    "rules": rules,
                })
        if groups:
            name = f'{item["metadata"]["namespace"]}-{item["metadata"]["name"]}'.replace(".", "-")
            print(json.dumps({
                "file": f"{name}.yaml",
                "source": source,
                "doc": {"apiVersion": 1, "groups": groups},
            }))


if __name__ == "__main__":
    main()
