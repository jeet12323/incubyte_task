namespace :db do
  desc "Seed the demo workforce only when there are no employees yet (safe to run on every deploy)"
  task seed_if_empty: :environment do
    if Employee.exists?
      puts "Employees already present (#{Employee.count}); skipping seed."
    else
      Rake::Task["db:seed"].invoke
    end
  end
end
