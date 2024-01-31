oc patch StorageClass ocs-storagecluster-ceph-rbd --type merge --patch "$(cat storage_default.yaml)"
