#!/bin/bash

#
# Delete a big google bucket using gsutil.
# Instead of showing the name of every deleted file,
# Just count the lines of output from gsutil and log progress instead.
#
# Usage:
#
#  delete-bucket.sh bucket-name approximate-bucket-filecount
#

BUCKET_NAME=$1
NUM_FILES=#{2-100000000}
LOG_FILE=${BUCKET_NAME}-DELETION.log
SLOTS=32

CMD="gsutil -o GSUtil:parallel_process_count=${SLOTS} -o GSUtil:parallel_thread_count=4 -m rm -r gs://${BUCKET_NAME}"

if [[ $2 == "local" ]]; then
    echo "${CMD}"
    (${CMD} 2>&1) | (2>&1 ./tqdm-batch.py --total ${NUM_FILES} --miniters 10000 --ncols 70 >/dev/null | tee -a ${LOG_FILE})
elif [[ $2 == "local-nolog" ]]; then
    echo "${CMD}"
    (${CMD} 2>&1) | (2>&1 ./tqdm-batch.py --total ${NUM_FILES} --miniters 10000 --ncols 70 >/dev/null)
else
    bsub -n ${SLOTS} -N -o ${LOG_FILE} $0 ${BUCKET_NAME} local-nolog
fi
