# Copyright Red Hat
# SPDX-License-Identifier: Apache-2.0

PID=$(cat ${TF_DIR:-.}/sshuttle-pid-file)
kill $PID