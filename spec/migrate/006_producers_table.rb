Sequel.migration do
  change do
    create_table(:producers) do
      primary_key :id
      String :name
      Date :date_of_birth
      DateTime :created_at
    end
  end
end
