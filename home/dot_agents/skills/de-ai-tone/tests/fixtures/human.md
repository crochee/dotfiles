# Retry policy for the ingest worker

The ingest worker retries a failed batch three times with exponential backoff. Waits are 2 s, 8 s and 32 s, plus up to 1 s of jitter. After the third failure the batch moves to `failed_batches` and the on-call rotation is paged.

Three retries is deliberate. The upstream provider clears most transient faults inside 30 s. We tried six. p99 end-to-end latency rose from 41 s to 6 min and the success rate did not move: of 1,240 batches in March, every fault that survived the third attempt also survived the sixth. So the extra three attempts bought nothing we could measure.

The dead-letter table stores the original payload, the attempt count and the last error string. An operator runs `replay.py --batch <id>` to re-enqueue one payload; the script records the user and the timestamp.

Two known gaps. Retries stop when the queue backs up past 10,000 messages, and the alerting rule for that condition still fires on the old threshold.

## 中文

摄取任务失败后会重试三次，间隔是 2 秒、8 秒和 32 秒，另加最多 1 秒的抖动。第三次仍然失败时，批次写进 `failed_batches` 表，同时呼叫值班人员。

重试三次是算过账的。上游服务的大部分瞬时故障在 30 秒内恢复。我们试过六次：p99 端到端延迟从 41 秒涨到 6 分钟，成功率没有变化。三月份 1240 个批次的记录显示，撑过第三次的故障也会撑过第六次。多出来的三次重试没有换来任何可测量的收益。

死信表保存原始负载、尝试次数和最后一次错误文本。值班人员执行 `replay.py --batch <id>` 重新入队单条负载，脚本会记下操作人和时间。

还有两个已知缺口：队列积压超过 10000 条时重试会停止，而这条告警规则用的还是旧阈值。
