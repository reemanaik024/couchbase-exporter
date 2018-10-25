local grafana = import 'grafonnet/grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local singlestat = grafana.singlestat;
local graphPanel = grafana.graphPanel;
local prometheus = grafana.prometheus;

dashboard.new(
  'Couchbase5',
  refresh='10s',
  time_from='now-1h',
  tags=['couchbase'],
  editable=true,
)
.addTemplate(
  grafana.template.datasource(
    'PROMETHEUS_DS',
    'prometheus',
    'Prometheus',
    hide='label',
  )
)
.addTemplate(
  grafana.template.new(
    'instance',
    '$PROMETHEUS_DS',
    'label_values(couchbase_bucket_basicstats_dataused, instance)',
    label='Instance',
    refresh='load',
  )
)
.addTemplate(
  grafana.template.new(
    'bucket',
    '$PROMETHEUS_DS',
    'label_values(couchbase_bucket_basicstats_dataused{instance="$instance"}, bucket)',
    label='Bucket',
    refresh='load',
    multi=true,
    includeAll=true,
  )
)
.addRow(
  row.new(
    title='General',
    collapse=false,
  )
  .addPanel(
    singlestat.new(
      'Balanced',
      datasource='Prometheus',
      span=2,
      valueName='current',
      colorBackground=true,
      valueFontSize='200%',
      thresholds='0,1',
      colors=[
        '#d44a3a',
        '#299c46',
        '#299c46',
      ],
      valueMaps=[
        {
          value: 'null',
          op: '=',
          text: 'N/A',
        },
        {
          value: '1',
          op: '=',
          text: 'YES',
        },
        {
          value: '0',
          op: '=',
          text: 'NO',
        },
      ]
    )
    .addTarget(
      prometheus.target(
        'couchbase_cluster_balanced{instance=~"$instance"}',
      )
    )
  )
  .addPanel(
    singlestat.new(
      'Rebalance Progress',
      format='percent',
      datasource='Prometheus',
      span=2,
      valueName='current',
      gaugeShow=true,
      gaugeThresholdMarkers=false,
      valueMaps=[
        {
          value: 'null',
          op: '=',
          text: 'N/A',
        },
        {
          value: '0',
          op: '=',
          text: 'OK',
        },
      ]
    )
    .addTarget(
      prometheus.target(
        'couchbase_task_rebalance_progress{instance=~"$instance"}',
      )
    )
  )
  .addPanel(
    singlestat.new(
      'Compacting Progress',
      format='percent',
      datasource='Prometheus',
      span=2,
      valueName='current',
      gaugeShow=true,
      gaugeThresholdMarkers=false,
      valueMaps=[
        {
          value: 'null',
          op: '=',
          text: 'N/A',
        },
        {
          value: '0',
          op: '=',
          text: 'OK',
        },
      ]
    )
    .addTarget(
      prometheus.target(
        'avg(couchbase_task_compacting_progress{instance=~"$instance"})',
      )
    )
  )
  .addPanel(
    singlestat.new(
      'Bucket RAM Usage',
      datasource='Prometheus',
      span=2,
      valueName='current',
      gaugeShow=true,
      gaugeThresholdMarkers=true,
      thresholds='70,90',
      format='percent',
    )
    .addTarget(
      prometheus.target(
        'avg(100 * (sum by (bucket) (couchbase_bucket_basicstats_memused{bucket=~"$bucket",instance=~"$instance"})) / sum by (bucket) (couchbase_bucket_stats_ep_max_size{bucket=~"$bucket",instance=~"$instance"}))',
      )
    )
  )
  .addPanel(
    singlestat.new(
      'Server Count',
      format='none',
      datasource='Prometheus',
      span=2,
      valueName='current',
      sparklineFull=true,
      sparklineShow=true,
    )
    .addTarget(
      prometheus.target(
        'count(couchbase_node_interestingstats_ops{instance=~"$instance"})',
      )
    )
  )
  .addPanel(
    singlestat.new(
      'Bucket QPS',
      format='none',
      datasource='Prometheus',
      span=2,
      valueName='current',
      sparklineFull=true,
      sparklineShow=true,
    )
    .addTarget(
      prometheus.target(
        'avg(sum by (bucket) (couchbase_bucket_stats_cmd_set{bucket=~"$bucket",instance=~"$instance"}) + sum by (bucket) (couchbase_bucket_stats_cmd_get{bucket=~"$bucket",instance=~"$instance"}))',
      )
    )
  )
)
.addRow(
  row.new(
    title='Details',
    collapse=false,
  )
  .addPanel(
    graphPanel.new(
      'QPS',
      span=12,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      min=0,
    )
    .addTarget(
      prometheus.target(
        'sum by (bucket) (couchbase_bucket_stats_cmd_set{bucket=~"$bucket",instance=~"$instance"}) + sum by (bucket) (couchbase_bucket_stats_cmd_get{bucket=~"$bucket",instance=~"$instance"})',
        legendFormat='{{ bucket }}',
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'Cache Miss Rate',
      span=12,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      format='percent',
      min=0,
      max=100,
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_cache_miss_rate{bucket=~"$bucket",instance=~"$instance"}',
        legendFormat='{{ bucket }}',
      )
    )
  )
)
.addRow(
  row.new(
    title='Queries',
    collapse=false,
  )
  .addPanel(
    graphPanel.new(
      'Gets / Sets',
      span=12,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
    )
    .addSeriesOverride(
      {
        alias: '/set/',
        transform: 'negative-Y',
      }
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_cmd_set{bucket=~"$bucket",instance=~"$instance"}',
        legendFormat='Sets on {{ bucket }}',
      )
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_cmd_get{bucket=~"$bucket",instance=~"$instance"}',
        legendFormat='Gets on {{ bucket }}',
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'Evictions',
      span=6,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      min=0,
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_evictions{bucket=~"$bucket",instance=~"$instance"}',
        legendFormat='{{ bucket }}',
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'Miss Rate',
      span=6,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      format='percent',
      min=0,
      max=100,
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_cache_miss_rate{bucket=~"$bucket",instance=~"$instance"}',
        legendFormat='{{ bucket }}',
      )
    )
  )
)
.addRow(
  row.new(
    title='Memory',
    collapse=true,
  )
  .addPanel(
    graphPanel.new(
      'Memory Used',
      span=12,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      format='decbytes',
      min=0,
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_basicstats_memused{bucket=~"$bucket",instance=~"$instance"}',
        legendFormat='{{ bucket }}.Usage',
      )
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_mem_high_wat{bucket=~"$bucket",instance=~"$instance"}',
        legendFormat='{{ bucket }}.HighWatermark',
      )
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_mem_low_wat{bucket=~"$bucket",instance=~"$instance"}',
        legendFormat='{{ bucket }}.LowWatermark',
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'Items Count',
      span=6,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      min=0,
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_curr_items{bucket=~"$bucket",instance=~"$instance"}',
        legendFormat='{{ bucket }}',
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'Hard Out of Memory Errors',
      span=6,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      min=0,
    )
    .addTarget(
      prometheus.target(
        'rate(couchbase_bucket_stats_ep_oom_errors{instance="$instance", bucket=~"$bucket"}[5m])',
        legendFormat='{{ bucket }}',
      )
    )
  )
)
.addRow(
  row.new(
    title='Compacting',
    collapse=true,
  )
  .addPanel(
    graphPanel.new(
      'Fragmentation',
      span=6,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      format='percent',
      min=0,
      max=100,
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_couch_docs_fragmentation{instance=~"$instance", bucket=~"$bucket"}',
        legendFormat='{{ bucket }}',
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'Compaction Progress',
      span=6,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      format='percent',
      min=0,
      max=100,
      nullPointMode='null as zero',
    )
    .addTarget(
      prometheus.target(
        'couchbase_task_compacting_progress{instance=~"$instance", bucket=~"$bucket"}',
        legendFormat='{{ bucket }}',
      )
    )
  )
)
.addRow(
  row.new(
    title='Rebalance',
    collapse=true,
  )
  .addPanel(
    graphPanel.new(
      'Rebalance Progress',
      span=6,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      format='percent',
      min=0,
      max=100,
      nullPointMode='null as zero',
    )
    .addTarget(
      prometheus.target(
        'couchbase_task_rebalance_progress{instance=~"$instance"}',
        legendFormat='',
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'DCP Replication',
      span=6,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      min=0,
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_dcp_replica_producer_count{instance=~"$instance", bucket=~"$bucket"}',
        legendFormat='{{ bucket }}: DCP Senders',
      )
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_dcp_replica_count{instance=~"$instance", bucket=~"$bucket"}',
        legendFormat='{{ bucket }}: DCP Connections',
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'Items Sent / Remaining',
      span=12,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
    )
    .addSeriesOverride(
      {
        alias: '/remaining/',
        transform: 'negative-Y',
      }
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_dcp_replica_items_sent{instance=~"$instance", bucket=~"$bucket"}',
        legendFormat='Sent on {{ bucket }}',
      )
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_dcp_replica_items_remaining{instance=~"$instance", bucket=~"$bucket"}',
        legendFormat='Remaining on {{ bucket }}',
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'Speed',
      span=12,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      format='Bps',
      min=0,
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_dcp_replica_total_bytes{instance=~"$instance", bucket=~"$bucket"}',
        legendFormat='{{ bucket }}',
      )
    )
  )
)
.addRow(
  row.new(
    title='XDCR',
    collapse=true,
  )
  .addPanel(
    graphPanel.new(
      'Items Sent / Remaining',
      span=12,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
    )
    .addSeriesOverride(
      {
        alias: '/remaining/',
        transform: 'negative-Y',
      }
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_dcp_xdcr_items_remaining{bucket=~"$bucket",instance=~"$instance"}',
        legendFormat='{{ bucket }}: Remaining',
      )
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_dcp_xdcr_items_sent{bucket=~"$bucket", instance=~"$instance"}',
        legendFormat='{{ bucket }}: Sent'
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'Speed',
      span=12,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      format='Bps',
      min=0,
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_dcp_xdcr_total_bytes{bucket=~"$bucket", instance=~"$instance"}',
        legendFormat='{{ bucket }}',
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'Backlog Size',
      span=6,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      min=0,
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_dcp_xdcr_total_backlog_size{bucket=~"$bucket", instance=~"$instance"}',
        legendFormat='{{ bucket }}'
      )
    )
  )
  .addPanel(
    graphPanel.new(
      'DCP',
      span=6,
      legend_alignAsTable=true,
      legend_rightSide=true,
      legend_values=true,
      legend_current=true,
      legend_sort='current',
      legend_sortDesc=true,
      min=0,
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_dcp_xdcr_count{bucket=~"$bucket", instance=~"$instance"}',
        legendFormat='{{ bucket }}: connections'
      )
    )
    .addTarget(
      prometheus.target(
        'couchbase_bucket_stats_ep_dcp_xdcr_producer_count{bucket=~"$bucket", instance=~"$instance"}',
        legendFormat='{{ bucket }}: producers'
      )
    )
  )
)