[![](https://badge.imagelayers.io/graho/backup-gpg-s3:latest.svg)](https://imagelayers.io/?images=graho/backup-gpg-s3:latest 'Get your own badge on imagelayers.io')

# graho/backup-gpg-s3

Compress a folder with XZ Utils, encrypt it with GPG and store it on AWS S3. Very simple. Just 40 lines of code.

Why should you encrypt your private files before uploading them on S3? Because nobody respects privacy these days. Nobody.


# Quick Start

Step 1. Create an S3 bucket on AWS. Write down the AWS region that was used to create the bucket and don't lose it.

Step 2. Create an AWS User in AWS IAM that is going to be used to backup a folder in the just created bucket. Write down the ```Access Key ID``` and the ```Secret Access Key``` and don't lose it.

Step 3. Create the following policy in AWS IAM

```json
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "Stmt1454689922000",
              "Effect": "Allow",
              "Action": [
                  "s3:PutObject"
              ],
              "Resource": [
                  "arn:aws:s3:::myBackupBucket/*"
              ]
          }
      ]
  }
```

and attach it to the User created in Step 2. Replace myBackupBucket with the name you gave to the bucket in Step 1 and be careful to append ```/*``` to it.

Step 4. Copy a public gpg key into a folder that can be mount by the docker container later. It is going to be used to encrypt your backup. Write down the email address of the gpg key and don't lose it.

Step 5. Run the container

```bash
docker run -d \
  --name my-backup \
  --restart=always \
  --volume /path/to/backup:/backup/:ro \
  --volume /path/to/gpg/keys/:/keys/:ro \
  --env "CRON_INTERVAL=0 4 * * * " \
  --env "GPG_RECIPIENT=myBackup@myDomain.com" \
  --env "S3_BUCKET_NAME=myBackupBucket" \
  --env "AWS_ACCESS_KEY_ID=myAWSAccessKey" \
  --env "AWS_SECRET_ACCESS_KEY=myAWSSecretAccess" \
  --env "AWS_DEFAULT_REGION=regionOfMyS3Bucket" \
  graho/backup-gpg-s3
```

This container is going to perform a backup every day at 4 am. You can define the backup schedule with ```CRON_INTERVAL```. You need to adjust the the environment variables to your own data.

# Confirm that your backup container is set up properly

Step 1. Check if Cron is set up

```bash
docker exec my-backup crontab -l
```

It should show your environment variables and the Cron interval, followed by ```/backup.sh```.

Step 2. Check if your public gpg key was imported

```bash
docker exec my-backup gpg --list-keys
```

and confirm that the email adress is the same as the one you assigned to ```GPG_RECIPIENT``` while starting the backup container.

Step 3. Initiate backup manually.

```bash
docker exec my-backup bash /backup.sh
```

This could take a while if the folder the backup is set up for is bigger than 100MB. After it's done, check if there is a file in your AWS bucket.


# Prepare Backup Restore

Before you can restore from a backup, you have to create another AWS IAM policy. You can/should do that before actually being in a situation where you need to restore from a backup.

Create another policy that is needed for restoring from a previously made backup:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1456142648000",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::myBackupBucket/*",
                "arn:aws:s3:::myBackupBucket"
            ]
        }
    ]
}
```

# Backup Restore

You should perform a backup restore before actually needing to restore from a backup, just to make sure that everything works the way it's supposed to.

Step 1. Attach the policy created in [Prepare Backup Restore](#prepare-backup-restore) to the user that is used for making backups. Now that user is able to restore from backups, too.

Step 2. Copy the private gpg key into a folder that can be mount by the restore container later.

Step 3. Start the restore container

```bash
docker run -it -rm \
  --volume /path/to/restore/folder:/restore/:rw \
  --volume /path/to/gpg/keys/:/keys/:ro \
  --env "GPG_RECIPIENT=myBackup@myDomain.com" \
  --env "S3_BUCKET_NAME=myBackupBucket" \
  --env "AWS_ACCESS_KEY_ID=myAWSAccessKey" \
  --env "AWS_SECRET_ACCESS_KEY=myAWSSecretAccess" \
  --env "AWS_DEFAULT_REGION=regionOfMyS3Bucket" \
  graho/backup-gpg-s3 bash /restore.sh
```

You will be asked to enter the name of the backup. If your private gpg key has a password you will be asked for it, too.


# FAQs

#### Q: How do I generate a GPG key?

Create a key with ```gpg --gen-key``` and export them.


#### Q: How do I export a GPG Key from my key chain, so that it can be used in a container volume?


```bash
gpg --output ~/path/to/volume/myKey.gpg.pub --export myBackup@myDomain.com

gpg --output ~/path/to/volume/myKey.gpg --export-secret-keys myBackup@myDomain.com
```

#### Q: What can I do if I generate a GPG Key and it tells me I need more entropy?

Fedora/Rh/Centos types: ```sudo yum install rng-tools```

On deb types: ```sudo apt-get install rng-tools``` to set it up.

Then run ```sudo rngd -r /dev/urandom```

#### Q: The backup container makes backups every day / every week, but it doesn't delete old backup files. How can I delete old backups?

You can define a lifecycle in the properties of your S3 bucket.
