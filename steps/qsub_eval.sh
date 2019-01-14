#!/bin/bash
#$ -cwd
#$ -S /bin/bash
#$ -m eas
#$ -l gpu=1,hostname=!c06*&b1[1234589]*|c*|b2*,ram_free=8G,mem_free=8G,h_rt=72:00:00
#$ -r no
set -e
device=`free-gpu`


if [ $# -le 3 ]; then
  echo "Usage:"
  echo "$0 <arch> <model_dir> <test_data_dir1> [<test_data_dir2> ...] [opts]"
  echo "optional arguments:"
  echo "  --batch-size             <100>"
  echo "  --intermediate-model-num"
  exit 1;
fi

arch=$1
model_dir=$2
test_data_dirs=""
shift 2
batch_size=100

echo "args:"
echo "  arch: $arch"
echo "  model_dir: $model_dir"

# Parse remaining arguments
while true; do
  [ -z "${1:-}" ] && break;
  case "$1" in
    --*) name=$(echo "$1" | sed 's/--//g' | sed 's/-/_/g')
      printf -v $name "$2"
      echo "  $name: $2"
      shift 2
      ;;
    *) test_data_dirs="$test_data_dirs $1"
      echo "  test_data_dir: $1"
      shift 1
      ;;
  esac
done
echo ""


if [ -z "$intermediate_model_num" ]; then
  model=$model_dir/final.mdl
  base_dir_out=$model_dir/output_final
else
  model=$model_dir/intermediate_models/${intermediate_model_num}.mdl
  base_dir_out=$model_dir/output_$intermediate_model_num
fi


echo "Working on machine $HOSTNAME"

for data_dir in $test_data_dirs; do
  eval_feats=$data_dir/feats_test.scp
  dir_out=$base_dir_out/$(basename $data_dir)/masks
  python3 steps/eval_qsub.py $arch $device $model $eval_feats $dir_out \
                             --batch-size $batch_size
done
