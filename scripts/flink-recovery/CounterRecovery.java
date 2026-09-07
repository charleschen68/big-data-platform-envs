import org.apache.flink.api.common.functions.RichMapFunction;
import org.apache.flink.api.common.state.ListState;
import org.apache.flink.api.common.state.ListStateDescriptor;
import org.apache.flink.api.common.state.ValueState;
import org.apache.flink.api.common.state.ValueStateDescriptor;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.runtime.state.FunctionInitializationContext;
import org.apache.flink.runtime.state.FunctionSnapshotContext;
import org.apache.flink.streaming.api.checkpoint.CheckpointedFunction;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.source.RichParallelSourceFunction;

/** Isolated recovery acceptance job: never accesses business sources or sinks. */
public final class CounterRecovery {
    public static final class CounterSource extends RichParallelSourceFunction<Long>
            implements CheckpointedFunction {
        private volatile boolean running = true;
        private long next;
        private transient ListState<Long> state;
        @Override public void run(SourceContext<Long> ctx) throws Exception {
            while (running) {
                synchronized (ctx.getCheckpointLock()) { ctx.collect(next++); }
                Thread.sleep(50);
            }
        }
        @Override public void cancel() { running = false; }
        @Override public void snapshotState(FunctionSnapshotContext ctx) throws Exception {
            state.clear(); state.add(next);
        }
        @Override public void initializeState(FunctionInitializationContext ctx) throws Exception {
            state = ctx.getOperatorStateStore().getListState(new ListStateDescriptor<>("next", Long.class));
            if (ctx.isRestored()) {
                for (Long value : state.get()) { next = value; }
                System.out.println("RECOVERY_STATE_RESTORED next=" + next);
            }
        }
    }
    public static final class CheckSequence extends RichMapFunction<Long, Long> {
        private transient ValueState<Long> expected;
        @Override public void open(Configuration ignored) {
            expected = getRuntimeContext().getState(new ValueStateDescriptor<>("expected", Long.class));
        }
        @Override public Long map(Long value) throws Exception {
            Long stored = expected.value();
            long want = stored == null ? 0 : stored;
            if (value != want) { throw new IllegalStateException("State mismatch: expected " + want + " got " + value); }
            expected.update(value + 1);
            return value;
        }
    }
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(1);
        env.enableCheckpointing(10000);
        env.addSource(new CounterSource()).uid("recovery-source")
            .keyBy(value -> 0).map(new CheckSequence()).uid("recovery-sequence")
            .filter(value -> value % 100 == 0).print("RECOVERY_COUNTER").uid("recovery-output");
        env.execute("flink-state-recovery-acceptance");
    }
}
