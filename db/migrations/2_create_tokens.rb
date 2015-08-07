Sequel.migration do
  up do
    create_table :access_tokens do
      primary_key :id
      String :access_token, size: 255
      Time :created_at
    end
  end

  down do
    drop_table :access_tokens
  end
end
