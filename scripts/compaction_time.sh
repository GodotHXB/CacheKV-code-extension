﻿#!/bin/bash
#set -x

NUMTHREAD=1
BENCHMARKS="fillrandom,readrandom"
NUMKEYS="10000000"
# NoveLSM specific parameters
# NoveLSM uses memtable levels, always set to num_levels 2
# write_buffer_size DRAM memtable size in MBs
# write_buffer_size_2 specifies NVM memtable size; set it in few GBs for perfomance;
OTHERPARAMS="--num_levels=2 --write_buffer_size=$DRAMBUFFSZ --nvm_buffer_size=$NVMBUFFSZ"
CACHEKVPARAMS_BASE="--dlock_way=4 --dlock_size=12582912 --skiplistSync_threshold=65536 --subImm_partition=0 --subImm_thread=4"
NUMREADTHREADS="0"
VALUSESZ=64
COMPACTIMM_THRESHOLD_VALUES=(2048)

SETUP() {
  if [ -z "$TEST_TMPDIR" ]
  then
        echo "DB path empty. Run source scripts/setvars.sh from source parent dir"
        exit
  fi
  rm -rf $TEST_TMPDIR/*
  mkdir -p $TEST_TMPDIR
}

MAKE() {
  cd $NOVELSMSRC
  # make clean
  sudo make -j8
}

for COMPACTIMM_THRESHOLD in "${COMPACTIMM_THRESHOLD_VALUES[@]}"; do
    for RUN in {1..5}; do
        echo "Running with --compactImm_threshold=${COMPACTIMM_THRESHOLD}, Run #${RUN}"
        CACHEKVPARAMS="$CACHEKVPARAMS_BASE --compactImm_threshold=$COMPACTIMM_THRESHOLD"
        SETUP
        MAKE
        modprobe msr
        ulimit -Sn 10240
        $APP_PREFIX $DBBENCH/db_bench --threads=$NUMTHREAD --num=$NUMKEYS \
        --benchmarks=$BENCHMARKS --value_size=$VALUSESZ $OTHERPARAMS $CACHEKVPARAMS --num_read_threads=$NUMREADTHREADS
        SETUP
    done
done