#!/bin/sh

gpg --import /keys/*

aws s3 ls s3://$S3_BUCKET_NAME
echo "These are the files currently available in your backup bucket."
echo "Which file contains the backup you want to restore from?"
echo -n "File name: "
read RESTORE_FILE

cd /restore

aws s3 cp s3://$S3_BUCKET_NAME/$RESTORE_FILE .

gpg --output ./restore.tar.xz --decrypt $RESTORE_FILE

tar xf ./restore.tar.xz

rm restore.tar.xz
rm $RESTORE_FILE

exit
