# Demo sign-in accounts (see DemoAccounts), then a deterministic workforce.
# Override the workforce size with: SEED_COUNT=500 bin/rails db:seed
DemoAccounts.ensure!

count = Integer(ENV.fetch("SEED_COUNT", 10_000))
started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

EmployeeSeeder.new(count:).call

elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
puts format("Seeded %<count>d employees in %<seconds>.2fs", count: Employee.count, seconds: elapsed)
