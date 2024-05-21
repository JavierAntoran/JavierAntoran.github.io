if [ -z "$1" ]; then
  echo "Error: No config_name key provided."
  echo "Usage: $0 config-name"
  exit 1
fi 

rm -rf /tmp/libtpu_lockfile /tmp/tpu_logs


cd /nfs_share/gen-md
~/miniconda3/envs/genmd/bin/python ~/nfs_share/gen-md/train_run/rundiff.py --config-name=$1  multihost=true
