# Percona Server 5.7 Multi-Architecture Docker Image

This is essentially something I've put together for a friends.

You'll likely need to update the scripts in `bin/mysql-start` and `bin/mysql-stop`.

If you have your own my.cnf you want copied in, place it at `conf/my.cnf`, and uncomment
line 116 of the Dockerfile.

Build with [`./make.sh`](make.sh). You'll probably want to update this with another tag,
so things get pushed somewhere. The local registry won't accept multi-arch images, so
you need to push it somewhere unless you're simply verifying the build works.

This should not be used for production, but seems to work pretty well for local
development. The Dockerfile can likely be improved. Things labeled with "##!!##" may
be extarneous or not needed.