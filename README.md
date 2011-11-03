# ec2-delete-old-snapshots.rb

A Ruby port of [ec2-delete-old-snapshots](http://code.google.com/p/ec2-delete-old-snapshots/)

Automatically delete old EBS snapshots from Amazon EC2.  Behaves just like the PHP version, except that it expects
a ~/.awssecret file to read credentials from, in the format:

```
aws-access-key-id
aws-secret-access-key
```

Usage: `ec2-delete-old-snapshots.rb [-v VOL_ID] [-o DAYS]`

You can specify the -v option multiple times to delete snapshots of multiple volumes in a
single invocation.
