Sequel.migration do
  up do
    create_table :ooo_entries do
      primary_key :id
      String :slack_id, size: 255
      String :slack_name, size: 255
      Date :start_date
      Date :end_date
      String :note, text: true
    end
  end

  down do
    drop_table :ooo_entries
  end
end
