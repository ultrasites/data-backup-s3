# data-backup-s3

Data file backup to S3 instances!

## Overview

This is the easiest way to backup your files to s3 based von python running in a docker container.

The following features are available:

- backup data with the given volume
- automatic upload to S3 (e.g. [MinIO](https://min.io), AWS, ...)
- connect to any container running on the same system
- select how often to run a backup
- select when to start the first backup, whether time of day or relative to container start time

## Backup

To run a backup, launch <code>data-backup-s3</code> image as a container with the correct parameters. Everything is controlled by environment variables passed to the container.

For example:

<code>docker run -d --restart=always -e BACKUP_FREQ=60 -e BACKUP_BEGIN=2330 -e S3_TARGET=s3://... -v /local/file/path:/home/backupuser/data ultrasites/data-backup-s3</code>

The above will run a backup every 60 minutes, beginning at the next 2330 local time.

### Environment

- <code>BACKUP_FREQ</code>: How often to do a BACKUP, in minutes. Defaults to 1440 minutes, or once per day.
- <code>BACKUP_BEGIN</code>: What time to do the first BACKUP. Defaults to immediate. Must be in one of two formats:
  - Absolute: HHMM, e.g. 2330 or 0415
  - Relative: +MM, i.e. how many minutes after starting the container, e.g. +0 (immediate), +10 (in 10 minutes), or +90 in an hour and a half
- <code>BACKUP_CRON</code>: Set the BACKUP schedule using standard crontab syntax, a single line.
- <code>RUN_ONCE</code>: Run the backup once and exit if RUN_ONCE is set. Useful if you use an external scheduler (e.g. as part of an orchestration solution like Cattle or Docker Swarm or kubernetes cron jobs) and don't want the container to do the scheduling internally. If you use this option, all other scheduling options, like BACKUP_FREQ and BACKUP_BEGIN and BACKUP_CRON, become obsolete.
- <code>BACKUP_DEBUG</code>: If set to true, print copious shell script messages to the container log. Otherwise only basic messages are printed.
- <code>BACKUP_TARGET</code>:
  S3 target with the format s3://bucketname/path. Connection via awscli.
- <code>AWS_ACCESS_KEY_ID</code>: AWS Key ID
- <code>AWS_SECRET_ACCESS_KEY</code>: AWS Secret Access Key
- <code>AWS_DEFAULT_REGION</code>: Region in which the bucket resides
- <code>AWS_ENDPOINT_URL</code>: Specify an alternative endpoint for s3 interopable systems e.g. Digitalocean
- <code>AWS_CLI_OPTS</code>: Additional arguments to be passed to the aws part of the aws s3 cp command, click here for a list. Be careful, as you can break something!
- <code>AWS_CLI_S3_CP_OPTS</code>: Additional arguments to be passed to the s3 cp part of the aws s3 cp command, click here for a list. If you are using AWS KMS, sse, sse-kms-key-id, etc., may be of interest.
- <code>COMPRESSION</code>: Compression to use. Supported are: gzip (default), bzip2
- <code>TMP_PATH</code>: tmp directory to be used during backup creation and other operations. Optional, defaults to /tmp

### Scheduling

There are several options for scheduling how often a backup should run:

- <code>RUN_ONCE</code>: run just once and exit.
- <code>BACKUP_FREQ</code> and <code>BACKUP_BEGIN</code>: run every x minutes, and run the first one at a particular time.
- <code>BACKUP_CRON</code>: run on a schedule.
  Cron Scheduling
  If a cron-scheduled backup takes longer than the beginning of the next backup window, it will be skipped. For example, if your cron line is scheduled to backup every hour, as follows:

<code>0 \* \* \* \*</code>
And the backup that runs at 13:00 finishes at 14:05, the next backup will not be immediate, but rather at 15:00.

The cron algorithm is as follows: after each backup run, calculate the next time that the cron statement will be true and schedule the backup then.

#### Order of Priority

The scheduling options have an order of priority:

<code>RUN_ONCE</code> runs once, immediately, and exits, ignoring everything else.
<code>BACKUP_CRON</code>: runs according to the cron schedule, ignoring BACKUP_FREQ and BACKUP_BEGIN.
<code>BACKUP_FREQ</code> and <code>BACKUP_BEGIN</code>: if nothing else is set.

### Permissions

By default, the backup/restore process does not run as root (UID O). Whenever possible, you should run processes (not just in containers) as users other than root. In this case, it runs as username appuser with UID/GID 1005.

In most scenarios, this will not affect your backup process negatively. However, if you are using the "Local" BACKUP target, i.e. your <code>BACKUP_TARGET</code> starts with / - and, most likely, is a volume mounted into the container - you can run into permissions issues. For example, if your mounted directory is owned by root on the host, then the backup process will be unable to write to it.

In this case, you have two options:

Run the container as root, docker run --user 0 ... or, in docker-compose.yml, user: "0"
Ensure your mounted directory is writable as UID or GID 1005.

### Forrmat

The BACKUP target is where you want the backup files to be saved. The backup file always is a compressed file the following format:

_data_backup_YYYY-MM-DDTHH:mm:ssZ.<code>compression</code>_

Where the date is RFC3339 date format, excluding the milliseconds portion.

YYYY = year in 4 digits
MM = month number from 01-12
DD = date for 01-31
HH = hour from 00-23
mm = minute from 00-59
ss = seconds from 00-59
T = literal character T, indicating the separation between date and time portions
Z = literal character Z, indicating that the time provided is UTC, or "Zulu"
compression = appropriate file ending for selected compression, one of: gz (gzip, default); bz2 (bzip2)
The time used is UTC time at the moment the BACKUP begins.

If you use a URL like s3://bucket/path, you can have it save to an S3 bucket.

Note that for s3, you'll need to specify your AWS credentials and default AWS region via <code>AWS_ACCESS_KEY_ID</code>, <code>AWS_SECRET_ACCESS_KEY</code> and <code>AWS_DEFAULT_REGION</code>

## About us

![](https://www.ultra-sites.de/wp-content/uploads/2022/02/logo_ultrasites-e1643806216404.png)

&copy; 2022 Ultra Sites Medienagentur

https://www.ultra-sites.de

Visit us on [Github](https://github.com/ultrasites)!
