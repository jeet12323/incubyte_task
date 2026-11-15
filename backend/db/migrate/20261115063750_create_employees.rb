class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :full_name, null: false
      t.string :email, null: false
      t.string :job_title, null: false
      t.string :department, null: false
      t.string :country_code, null: false, limit: 2
      t.decimal :salary, null: false, precision: 12, scale: 2
      t.string :employment_type, null: false, default: "full_time"
      t.date :hire_date, null: false

      t.timestamps
    end

    add_index :employees, :email, unique: true
    add_index :employees, :department
    add_index :employees, :job_title
    # Most insight queries group by country, then by job title within it.
    add_index :employees, %i[country_code job_title]
    add_index :employees, :salary
    add_check_constraint :employees, "salary > 0", name: "employees_salary_positive"
  end
end
