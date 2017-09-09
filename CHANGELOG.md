# 0.3.3

* Simplifies lock acquisition and tightens its restrictions, reducing chances of duplicate enqueues.

# 0.3.1.pre

* Improves Lock efficiency by removing one call to Redis during #extend.

# 0.3.0.pre

* Adds locking to prevent two or more processes in a race condition from enqueuing multiple copies of a job.

* Adds the `solo_lock_key_prefix` directive to set the lock key prefix for your job.

# 0.2.0

* Removes internal methods used by Solo from your Job class' namespace.

# 0.1.0

* Initial version of ActiveJob::Plugins::Resque::Solo.
