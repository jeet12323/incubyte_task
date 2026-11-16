namespace :db do
  desc "Create missing demo accounts, and seed the workforce only when there are no employees yet (safe on every deploy)"
  task seed_if_empty: :environment do
    DemoAccounts.ensure!

    if Employee.exists?
      puts "Employees already present (#{Employee.count}); skipping seed."
    else
      Rake::Task["db:seed"].invoke
    end
  end
end
