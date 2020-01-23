# 1.0.0

* Breaking change: Allow a job to reschedule itself while it executing but not enqueued.
* Adds `solo_self_enqueueing` as an option to control the re-enqueueing behavior. Use `solo_self_enqueueing :prevent` for the behavior prior to version 1.0.0.

# 0.3.9

* Add CI test for Ruby 2.5.0.

# 0.3.8

* Fix bug that caused ActiveJobResqueSolo to fail to realize that the Rails app was configued for Resque.

# 0.3.7

* Fix bug that would prevent resque-scheduler from enqueuing jobs with no arguments.

# 0.3.6

* Fix bug that would allow duplicate enqueues of jobs that had no arguments.

# 0.3.5

* Adds `solo_any_args` directive that will only allow one instance of a job class in the queue regardless of any arguments.

# 0.3.4

* Fix bug that could prevent enqueing with slowly performing locks.

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
