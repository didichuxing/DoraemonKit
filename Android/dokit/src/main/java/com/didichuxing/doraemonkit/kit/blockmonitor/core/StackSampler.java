package com.didichuxing.doraemonkit.kit.blockmonitor.core;

import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.text.TextUtils;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * @desc: 堆栈信息采集类
 */
public class StackSampler {
    private static final String TAG = "StackSampler";
    private static final int DEFAULT_SAMPLE_INTERVAL = 200;
    private static final int DEFAULT_MAX_ENTRY_COUNT = 100;
    private static final String SEPARATOR = "\r\n";
    private static final SimpleDateFormat TIME_FORMATTER =
            new SimpleDateFormat("MM-dd HH:mm:ss.SSS", Locale.CHINESE);

    private AtomicBoolean mRunning = new AtomicBoolean(false);
    private HandlerThread mStackThread;
    private Handler mStackHandler;

    private LinkedHashMap<Long, String> sStackMap = new LinkedHashMap<>();
    private String mFilterCache;

    public void init() {
        if (mStackThread == null) {
            mStackThread = new HandlerThread("BlockMonitor") {
                @Override
                protected void onLooperPrepared() {
                    mStackHandler = new Handler(mStackThread.getLooper());
                }
            };
            mStackThread.start();
        }
    }

    public void startDump() {
        if (mStackHandler == null) {
            return;
        }
        if (mRunning.get()) {
            return;
        }
        mRunning.set(true);
        mStackHandler.removeCallbacks(mRunnable);
        mStackHandler.postDelayed(mRunnable, DEFAULT_SAMPLE_INTERVAL);
    }

    public ArrayList<String> getThreadStackEntries(long startTime, long endTime) {
        ArrayList<String> result = new ArrayList<>();
        synchronized (sStackMap) {
            for (Long entryTime : sStackMap.keySet()) {
                if (startTime < entryTime && entryTime < endTime) {
                    result.add(TIME_FORMATTER.format(entryTime)
                            + SEPARATOR
                            + SEPARATOR
                            + sStackMap.get(entryTime));
                }
            }
        }
        return result;
    }

    public void stopDump() {
        if (mStackHandler == null) {
            return;
        }
        if (!mRunning.get()) {
            return;
        }
        mRunning.set(false);
        mFilterCache = null;
        mStackHandler.removeCallbacks(mRunnable);
    }

    public void shutDown() {
        stopDump();
        if (mStackThread != null) {
            mStackThread.quit();
        }
    }


    private Runnable mRunnable = new Runnable() {
        @Override
        public void run() {
            dumpInfo();
            if (mRunning.get()) {
                mStackHandler.postDelayed(mRunnable, DEFAULT_SAMPLE_INTERVAL);
            }
        }
    };

    private void dumpInfo() {
        StringBuilder stringBuilder = new StringBuilder();
        Thread thread = Looper.getMainLooper().getThread();
        for (StackTraceElement stackTraceElement : thread.getStackTrace()) {
            stringBuilder
                    .append(stackTraceElement.toString())
                    .append(SEPARATOR);
        }

        synchronized (sStackMap) {
            if (sStackMap.size() == DEFAULT_MAX_ENTRY_COUNT) {
                sStackMap.remove(sStackMap.keySet().iterator().next());
            }
            if (!shouldIgnore(stringBuilder)) {
                sStackMap.put(System.currentTimeMillis(), stringBuilder.toString());
            }
        }
    }

    /**
     * 过滤掉重复项
     *
     * @param builder
     * @return
     */
    private boolean shouldIgnore(StringBuilder builder) {
        if (TextUtils.equals(mFilterCache, builder.toString())) {
            return true;
        }
        mFilterCache = builder.toString();
        return false;
    }
}
