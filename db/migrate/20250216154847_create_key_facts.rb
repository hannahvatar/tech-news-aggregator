class CreateKeyFacts < ActiveRecord::Migration[7.1]
  def change
    create_table :key_facts do |t|

      t.timestamps
    end
  end
end
