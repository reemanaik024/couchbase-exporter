package collector

import (
	"sync"
	"time"

	"github.com/caarlos0/couchbase-exporter/client"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/common/log"
)

type clusterCollector struct {
	mutex  sync.Mutex
	client client.Client

	up             *prometheus.Desc
	scrapeDuration *prometheus.Desc

	balanced         *prometheus.Desc
	ftsMemoryQuota   *prometheus.Desc
	indexMemoryQuota *prometheus.Desc
	memoryQuota      *prometheus.Desc
	rebalanceStatus  *prometheus.Desc
	maxBucketCount   *prometheus.Desc

	countersRebalanceStart   *prometheus.Desc
	countersRebalanceSuccess *prometheus.Desc
	countersRebalanceFail    *prometheus.Desc
	countersFailoverNode     *prometheus.Desc

	storagetotalsRAMQuotatotal        *prometheus.Desc
	storagetotalsRAMQuotaused         *prometheus.Desc
	storagetotalsRAMUsed              *prometheus.Desc
	storagetotalsRAMQuotausedpernode  *prometheus.Desc
	storagetotalsRAMUsedbydata        *prometheus.Desc
	storagetotalsRAMTotal             *prometheus.Desc
	storagetotalsRAMQuotatotalpernode *prometheus.Desc

	storagetotalsHddTotal      *prometheus.Desc
	storagetotalsHddUsed       *prometheus.Desc
	storagetotalsHddQuotatotal *prometheus.Desc
	storagetotalsHddUsedbydata *prometheus.Desc
	storagetotalsHddFree       *prometheus.Desc
}

// NewClusterCollector cluster collector
func NewClusterCollector(client client.Client) prometheus.Collector {
	const ns = "cluster"
	return &clusterCollector{
		client: client,
		up: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "up"),
			"Couchbase cluster API is responding",
			nil,
			nil,
		),
		scrapeDuration: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "scrape_duration_seconds"),
			"Scrape duration in seconds",
			nil,
			nil,
		),
		balanced: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "balanced"),
			"Is the cluster balanced",
			nil,
			nil,
		),
		ftsMemoryQuota: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "fts_memory_quota_bytes"),
			"Memory quota allocated to full text search buckets",
			nil,
			nil,
		),
		indexMemoryQuota: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "index_memory_quota_bytes"),
			"Memory quota allocated to Index buckets",
			nil,
			nil,
		),
		memoryQuota: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "memory_quota_bytes"),
			"Memory quota allocated to Data buckets",
			nil,
			nil,
		),
		rebalanceStatus: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "rebalance_status"),
			"Rebalance status. 1: rebalancing",
			nil,
			nil,
		),
		maxBucketCount: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "max_bucket_count"),
			"Maximum number of buckets allowed",
			nil,
			nil,
		),
		countersRebalanceStart: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "counters_rebalance_start"),
			"Number of rebalance starts since cluster is up",
			nil,
			nil,
		),
		countersRebalanceSuccess: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "counters_rebalance_success"),
			"Number of rebalance successes since cluster is up",
			nil,
			nil,
		),
		countersRebalanceFail: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "counters_rebalance_fail"),
			"Number of rebalance fails since cluster is up",
			nil,
			nil,
		),
		countersFailoverNode: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "counters_failover_node"),
			"Number of failovers since cluster is up",
			nil,
			nil,
		),
		storagetotalsRAMQuotatotal: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "storagetotals_ram_quotatotal_bytes"),
			"Total memory allocated to Couchbase in the cluster",
			nil,
			nil,
		),
		storagetotalsRAMQuotaused: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "storagetotals_ram_quotaused_bytes"),
			"Memory quota used by the cluster",
			nil,
			nil,
		),
		storagetotalsHddTotal: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "storagetotals_hdd_total_bytes"),
			"Total disk space available to the cluster",
			nil,
			nil,
		),
		storagetotalsRAMUsed: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "storagetotals_ram_used_bytes"),
			"Memory used by the cluster",
			nil,
			nil,
		),
		storagetotalsHddUsed: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "storagetotals_hdd_used_bytes"),
			"Disk space used by the cluster",
			nil,
			nil,
		),
		storagetotalsRAMQuotausedpernode: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "storagetotals_ram_quotausedpernode_bytes"),
			"Memory quota used per node",
			nil,
			nil,
		),
		storagetotalsRAMUsedbydata: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "storagetotals_ram_usedbydata_bytes"),
			"Memory used by the data in the cluster",
			nil,
			nil,
		),
		storagetotalsHddQuotatotal: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "storagetotals_hdd_quotatotal_bytes"),
			"Disk space quota for the cluster",
			nil,
			nil,
		),
		storagetotalsHddUsedbydata: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "storagetotals_hdd_usedbydata_bytes"),
			"Disk space used by the data in the cluster",
			nil,
			nil,
		),
		storagetotalsRAMTotal: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "storagetotals_ram_total_bytes"),
			"Total memory available to the cluster",
			nil,
			nil,
		),
		storagetotalsRAMQuotatotalpernode: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "storagetotals_ram_quotatotalpernode_bytes"),
			"Total memory allocated to Couchbase per node",
			nil,
			nil,
		),
		storagetotalsHddFree: prometheus.NewDesc(
			prometheus.BuildFQName(globalNamespace, ns, "storagetotals_hdd_free_bytes"),
			"Free disk space in the cluster",
			nil,
			nil,
		),
	}
}

// Describe all metrics
func (c *clusterCollector) Describe(ch chan<- *prometheus.Desc) {
	ch <- c.up
	ch <- c.scrapeDuration

	ch <- c.balanced
	ch <- c.ftsMemoryQuota
	ch <- c.indexMemoryQuota
	ch <- c.memoryQuota
	ch <- c.rebalanceStatus
	ch <- c.maxBucketCount

	ch <- c.countersRebalanceStart
	ch <- c.countersRebalanceSuccess
	ch <- c.countersRebalanceFail
	ch <- c.countersFailoverNode

	ch <- c.storagetotalsRAMQuotatotal
	ch <- c.storagetotalsRAMQuotaused
	ch <- c.storagetotalsRAMUsed
	ch <- c.storagetotalsRAMQuotausedpernode
	ch <- c.storagetotalsRAMUsedbydata
	ch <- c.storagetotalsRAMTotal
	ch <- c.storagetotalsRAMQuotatotalpernode

	ch <- c.storagetotalsHddTotal
	ch <- c.storagetotalsHddUsed
	ch <- c.storagetotalsHddQuotatotal
	ch <- c.storagetotalsHddUsedbydata
	ch <- c.storagetotalsHddFree
}

// Collect all metrics
func (c *clusterCollector) Collect(ch chan<- prometheus.Metric) {
	c.mutex.Lock()
	defer c.mutex.Unlock()

	start := time.Now()
	log.Info("Collecting cluster metrics...")

	cluster, err := c.client.Cluster()
	if err != nil {
		ch <- prometheus.MustNewConstMetric(c.up, prometheus.GaugeValue, 0)
		log.With("error", err).Error("failed to scrape cluster")
		return
	}
	ch <- prometheus.MustNewConstMetric(c.up, prometheus.GaugeValue, 1)

	ch <- prometheus.MustNewConstMetric(c.balanced, prometheus.GaugeValue, fromBool(cluster.Balanced))
	ch <- prometheus.MustNewConstMetric(c.ftsMemoryQuota, prometheus.GaugeValue, float64(cluster.FtsMemoryQuota*1024*1024))
	ch <- prometheus.MustNewConstMetric(c.indexMemoryQuota, prometheus.GaugeValue, float64(cluster.IndexMemoryQuota*1024*1024))
	ch <- prometheus.MustNewConstMetric(c.memoryQuota, prometheus.GaugeValue, float64(cluster.MemoryQuota*1024*1024))
	ch <- prometheus.MustNewConstMetric(c.rebalanceStatus, prometheus.GaugeValue, fromBool(cluster.RebalanceStatus == "rebalancing"))
	ch <- prometheus.MustNewConstMetric(c.maxBucketCount, prometheus.GaugeValue, float64(cluster.MaxBucketCount))

	ch <- prometheus.MustNewConstMetric(c.countersRebalanceStart, prometheus.CounterValue, float64(cluster.Counters.RebalanceStart))
	ch <- prometheus.MustNewConstMetric(c.countersRebalanceSuccess, prometheus.CounterValue, float64(cluster.Counters.RebalanceSuccess))
	ch <- prometheus.MustNewConstMetric(c.countersRebalanceFail, prometheus.CounterValue, float64(cluster.Counters.RebalanceFail))
	ch <- prometheus.MustNewConstMetric(c.countersFailoverNode, prometheus.CounterValue, float64(cluster.Counters.FailoverNode))

	ch <- prometheus.MustNewConstMetric(c.storagetotalsRAMQuotatotal, prometheus.GaugeValue, float64(cluster.StorageTotals.RAM.QuotaTotal))
	ch <- prometheus.MustNewConstMetric(c.storagetotalsRAMQuotaused, prometheus.GaugeValue, float64(cluster.StorageTotals.RAM.QuotaUsed))
	ch <- prometheus.MustNewConstMetric(c.storagetotalsRAMUsed, prometheus.GaugeValue, float64(cluster.StorageTotals.RAM.Used))
	ch <- prometheus.MustNewConstMetric(c.storagetotalsHddUsed, prometheus.GaugeValue, float64(cluster.StorageTotals.Hdd.Used))
	ch <- prometheus.MustNewConstMetric(c.storagetotalsRAMQuotausedpernode, prometheus.GaugeValue, float64(cluster.StorageTotals.RAM.QuotaUsedPerNode))
	ch <- prometheus.MustNewConstMetric(c.storagetotalsRAMUsedbydata, prometheus.GaugeValue, float64(cluster.StorageTotals.RAM.UsedByData))
	ch <- prometheus.MustNewConstMetric(c.storagetotalsRAMTotal, prometheus.GaugeValue, float64(cluster.StorageTotals.RAM.Total))
	ch <- prometheus.MustNewConstMetric(c.storagetotalsRAMQuotatotalpernode, prometheus.GaugeValue, float64(cluster.StorageTotals.RAM.QuotaTotalPerNode))

	ch <- prometheus.MustNewConstMetric(c.storagetotalsHddTotal, prometheus.GaugeValue, float64(cluster.StorageTotals.Hdd.Total))
	ch <- prometheus.MustNewConstMetric(c.storagetotalsHddQuotatotal, prometheus.GaugeValue, float64(cluster.StorageTotals.Hdd.QuotaTotal))
	ch <- prometheus.MustNewConstMetric(c.storagetotalsHddUsedbydata, prometheus.GaugeValue, float64(cluster.StorageTotals.Hdd.UsedByData))
	ch <- prometheus.MustNewConstMetric(c.storagetotalsHddFree, prometheus.GaugeValue, float64(cluster.StorageTotals.Hdd.Free))

	ch <- prometheus.MustNewConstMetric(c.scrapeDuration, prometheus.GaugeValue, time.Since(start).Seconds())
}