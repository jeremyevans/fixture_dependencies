Sequel.migration do
  change do
    create_table(:ctis) do
      primary_key :id
      String :kind
      Integer :number
    end

    create_table(:cti_subs) do
      primary_key :id
      Integer :extra_number
    end

    create_table(:cti_mms) do
      primary_key :id
      Integer :kind_id
      Integer :number
    end

    create_table(:cti_mm_subs) do
      primary_key :id
      Integer :extra_number
    end
  end
end
