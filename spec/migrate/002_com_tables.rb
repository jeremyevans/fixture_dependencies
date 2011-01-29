Sequel.migration do
  change do
    create_table(:com_artists){Integer :id1; Integer :id2; String :name; primary_key [:id1, :id2]}
    create_table(:com_albums){Integer :id1; Integer :id2; String :name; Integer :artist_id1; Integer :artist_id2; primary_key [:id1, :id2]; foreign_key [:artist_id1, :artist_id2], :com_artists}
    create_table(:com_tags){Integer :id1; Integer :id2; String :name; primary_key [:id1, :id2]}
    create_table(:com_albums_com_tags){Integer :album_id1; Integer :album_id2; Integer :tag_id1; Integer :tag_id2; foreign_key [:album_id1, :album_id2], :com_albums; foreign_key [:tag_id1, :tag_id2], :com_tags}

    create_table(:com_self_refs){Integer :id1; Integer :id2; primary_key [:id1, :id2]; Integer :self_ref_id1; Integer :self_ref_id2; foreign_key [:self_ref_id1, :self_ref_id2], :com_self_refs}
  end
end
