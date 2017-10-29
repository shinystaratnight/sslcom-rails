class CreatePhysicalTokenBlocklistAndCaaCheck < ActiveRecord::Migration
  def change
    create_table :blocklist do |t|
      t.string     :type, required: true
      t.string     :domain, required: true
      t.integer    :validation
      t.string     :status
      t.string     :reason
      t.string     :description
      t.text       :notes
      t.timestamps
    end

    create_table :caa_check do |t|
      t.references  :checkable, :polymorphic=>true
      t.string      :domain, required: true
      t.string      :request
      t.text        :result
      t.timestamps
    end

    create_table :physical_token do |t|
      t.references  :certificate_order
      t.references  :signed_certificate
      t.string      :tracking_number
      t.string      :shipping_method
      t.string      :activation_pin
      t.string      :manufacturer
      t.string      :model_number
      t.string      :serial_number
      t.timestamps
    end
  end
end
