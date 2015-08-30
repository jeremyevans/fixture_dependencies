Sequel.migration do
  change do
    create_table(:accounts) do
      primary_key :id
      String :name
    end
    create_table(:addresses) do
      primary_key :id
      column :addressable_id, Integer
      column :addressable_type, String
      String :street
      String :city
    end
  end
end
