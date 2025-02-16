class AddArticleIdToKeyFacts < ActiveRecord::Migration[7.1]
  def change
    add_column :key_facts, :article_id, :integer
  end
end
