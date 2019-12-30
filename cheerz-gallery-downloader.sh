#!/bin/sh
# Bertrand B.

# Script parameters.
PARAM_GALERY_URL='';
PARAM_TARGET_DIR=$(readlink -f ./cheerz);

usage () {
  echo "Usage: $(basename "$0") URL [OPTIONS]";
  echo "Options:";
  echo "  -d PATH:      Save pictures in the specified folder. Default: $PARAM_TARGET_DIR."
  echo "  -h, --help:   Display usage."
}

configure () {
  while [ "$#" -gt "0" ]; do
    case "$1" in
      -d)
        PARAM_TARGET_DIR=$(readlink -f $2);
        shift 2;
        ;;
      -h | --help)
        usage;
        exit 0;
        ;;
      *)
        PARAM_GALERY_URL="$1";
        shift 1;
        ;;
    esac
  done
}

download () {
  echo "Getting list of all pictures from: $PARAM_GALERY_URL.";
  CHEERZ_DATA=$(wget -q $PARAM_GALERY_URL -O - | grep photoData | sed -e 's/<[^>]*>//g' | cut -d'=' -f 2- | jq '.photoData');
  JSON_DATA=$(echo $CHEERZ_DATA | jq 'sort_by(.taken_at)');

  NB_PICTURES=$(echo $JSON_DATA | jq 'length');

  echo "There is $NB_PICTURES pictures. They will be saved in $PARAM_TARGET_DIR.";
  echo 'Start downloading.';

  for i in `seq 0 $((NB_PICTURES - 1))`; do
      DATA=$(echo $JSON_DATA | jq ".[$i]");
      ID=$(echo $DATA | jq '.id' | sed 's/"//g');
      URL=$(echo $DATA | jq '.url' | sed 's/"//g');
      URL_ORIGINAL=$(echo $DATA | jq '.original_url' | sed 's/"//g');
      TAKEN_AT=$(echo $DATA | jq '.taken_at' | sed 's/"//g');

      EXTENSION='.jpg';
      IMG_CHEERZ=$PARAM_TARGET_DIR/$(date -d $TAKEN_AT '+%Y%m%d%H%M%S')-cheerz$EXTENSION;
      IMG_ORIGINAL=$PARAM_TARGET_DIR/$(date -d $TAKEN_AT '+%Y%m%d%H%M%S')-original$EXTENSION;
      EXIF_DATE=$(date -d $TAKEN_AT '+%Y:%m:%d %H:%M:%S');

      echo "[$((i + 1))/$NB_PICTURES] Downloading images $ID and setting up date to $EXIF_DATE.";
      wget -q --show-progress --progress=bar:scroll $URL -O $IMG_CHEERZ ;
      wget -q --show-progress --progress=bar:scroll $URL_ORIGINAL -O $IMG_ORIGINAL;
      exiftool -q -DateTimeOriginal="$EXIF_DATE" -UserComment="Cheerz image id: $ID." -overwrite_original $IMG_CHEERZ $IMG_ORIGINAL;
  done;

  echo 'Finished.';
}

run () {
  configure $*;
  if [ ! -d "$PARAM_TARGET_DIR" ]; then
    mkdir -vp "$PARAM_TARGET_DIR";
  fi
  download;
}

run $*;
