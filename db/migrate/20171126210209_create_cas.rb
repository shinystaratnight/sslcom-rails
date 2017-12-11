class CreateCas < ActiveRecord::Migration
  def change
    create_table :cas do |t|
      t.string  :ref # use this code in public apis; 1000's - Roots, 2000's - subCas, 3000's - end entity
      t.string  :friendly_name
      t.string  :profile_name # name as listed in EJBCA admin
      t.string  :algorithm # rsa or ecc
      t.integer :size # 2028, 4096, etc
      t.string  :description
      t.string  :profile_type # end entity, certificate profile, etc
    end
  end
end
