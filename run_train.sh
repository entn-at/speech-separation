#!/bin/bash

set -e

stage=0

arch=uPIT
train_set=mixer6_CH02_tr
cv_set=mixer6_CH02_cv
email= # set this if you would like qsub email and to run the train command in the background

featdir=`pwd`/feats
copy_data_to_gpu=true
start_epoch=0
num_epochs=200
batch_size=100


train_data_dir=data/$train_set
[ -z "$cv_set" ] || cv_data_dir=data/$cv_set
if [ -z "$email" ]; then
  opt="-sync y"
else
  opt="-M $email"
fi


# Data prep
if [ $stage -le 0 ]; then
  # Note: make sure the filelists/path.sh file contains appropriate information
  #  for each of your datasets
  echo "### Preparing data directories (stage 0) ###"

  for dataset in $train_set $cv_set; do
    local/prepare_data_dir.sh $dataset
  done
fi

# Extract features
if [ $stage -le 1 ]; then
  echo "### Extracting features (stage 1) ###"

  for data_dir in $train_data_dir $cv_data_dir; do
    steps/extract_feats.py $data_dir "train" $featdir/$(basename $data_dir)_train
  done
fi

# Train model
if [ $stage -le 2 ]; then
  echo "### Training model (stage 2) ###"

  exp_dir=exp/${arch}_${train_set}
  mkdir -p $exp_dir

  qsub -j y -o $exp_dir/train_\$JOB_ID.log $opt \
    steps/qsub_train.sh \
    $arch \
    $exp_dir \
    $train_data_dir \
    --cv-datadir "$cv_data_dir" \
    --copy-data-to-gpu "$copy_data_to_gpu" \
    --start-epoch "$start_epoch" \
    --num-epochs "$num_epochs" \
    --batch-size "$batch_size"
fi
