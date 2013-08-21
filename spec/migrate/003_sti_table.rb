Sequel.migration do
  change do
    create_table(:stis) do
      primary_key :id
      String :kind
      Integer :number
    end
  end
end
