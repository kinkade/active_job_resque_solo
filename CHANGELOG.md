# 0.3.0.pre

* Adds locking to prevent two or more processes in a race condition from enquing multiple copies of a job.

* Adds the `solo_lock_key_prefix` directive to set the lock key prefix for your job.

# 0.2.0

* Removes internal methods used by Solo from your Job class' namespace.

# 0.1.0

* Initial version of ActiveJob::Plugins::Resque::Solo.
