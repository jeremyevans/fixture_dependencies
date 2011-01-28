Sequel.migration do
  change do
    create_table(:artists){primary_key :id; String :name}
    create_table(:albums){primary_key :id; String :name; foreign_key :artist_id, :artists}
    create_table(:tags){primary_key :id; String :name}
    create_table(:albums_tags){foreign_key :album_id, :albums; foreign_key :tag_id, :tags; primary_key [:album_id, :tag_id]}

    create_table(:self_refs){primary_key :id; foreign_key :self_ref_id, :self_refs}
  end
end
