# ActiveJobResqueSolo

A plugin for ActiveJob with Resque to prevent duplicate enqueuing of jobs.

[![Build Status](https://travis-ci.org/kinkade/active_job_resque_solo.svg?branch=master)](https://travis-ci.org/kinkade/active_job_resque_solo)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_job_resque_solo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_job_resque_solo

## Usage

In your job class, include the plugin:

```ruby
class MyJob < ActiveJob::Base

  include ActiveJob::Plugins::Resque::Solo

  queue_as :default

  def perform(*args); end
end
```

If an instance of the job with matching arguments is either waiting for a worker or currently executing,
Solo will prevent a new instance of the job from being enqueued.

You can control which named arguments are used to determine uniqueness in the queue:

* `solo_only_args`
* `solo_except_args`
* `solo_any_args`

```ruby
class MyJob < ActiveJob::Base

  include ActiveJob::Plugins::Resque::Solo

  # Only compare "user" args when checking for duplicate jobs.
  solo_only_args :user

  queue_as :default

  def perform(user:, nonce:)
  end
end
```

Conversely, you can exclude arguments from being checked for duplicates.  This
is useful when plugins add arguments of their own to your jobs.

```ruby
class MyJob < ActiveJob::Base

  include ActiveJob::Plugins::Resque::Solo

  solo_except_args :nonce, :retry_count

  queue_as :default

  def perform(user:, nonce:)
  end
end
```

Specify `solo_any_args` to allow only one instance of your job to be enqueued or executing at any given
time regardless of the arguments used in each instance.

`solo_any_args` overrides `solo_only_args` and `solo_except_args`.

```ruby
class MyJob < ActiveJob::Base

  include ActiveJob::Plugins::Resque::Solo

  solo_any_args

  queue_as :default

  def perform(user: nil)
  end
end
```
## Locking

Solo uses an internal locking mechanism to prevent multiple processes from
enqueuing the same job during race conditions.  This gem does not perform any
locking around job execution.

The lock prevents competing jobs of the same class and arguments from being
enqueued, complying with the argument filtering programmed with `solo_only_args`
and `solo_except_args`.

The default Redis key prefix is "ajr_solo".  It can be set to a different,
arbitrary string of your choice using `solo_lock_key_prefix`:

```ruby
class MyJob < ActiveJob::Base

  include ActiveJob::Plugins::Resque::Solo

  solo_lock_key_prefix "my_lock_prefix"

  def perform(*args)
  end
end
```

## Re-enqueueing from within the job

The default behavior of this gem allows a Job to re-enqueue itself while it is
executing. If you know that your job should not be re-enqueueing itself, you can
prevent inadvertent re-enqueueing of the job by using `solo_self_enqueueing :prevent`.

Jobs that `fail` or `raise` an error may be retried by the framework, and are not
affected by this option.

```ruby
class MyJob < ActiveJob::Base

  include ActiveJob::Plugins::Resque::Solo

  solo_self_enqueueing :prevent

  def perform(*args)
     MyJob.perform_later # <== this will not enqueue a job because of :prevent, above.
     raise MyError       # <== retries are still allowed
  end
end
```

## Duplicate enqueues are possible

While this plugin will greatly reduce duplicate instances of a job from being
enqueued, a job may be enqueued multiple times if the Redis response times are
very slow. Slowness could be caused by extremely high load on Redis or networking
issues.

Since duplicate enqueueing of jobs is a possibility, make sure that that your code
does not rely on this gem for sensitive, critical sections of code that must not
be processed more than once.

The locks are acquired for dynamic amounts of time, but expire quickly, typically
in one second. Killed workers will not leave long-lived, orphaned locks to
adversely block jobs from being enqueued.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kinkade/active_job_resque_solo. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveJobResqueSolo project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/kinkade/active_job_resque_solo/blob/master/CODE_OF_CONDUCT.md).
