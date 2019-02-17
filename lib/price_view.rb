module PriceView

  # use this function to update prices via ResellerTier#update_prices
  def prices_matrix(indexed=true)
    if indexed
      prices={}
      product_variant_items.includes{product_variant_group}.map do |pvi|
        prices.merge!(pvi.id=>[pvi.product_variant_group.variantable(Certificate).title,
                               pvi.product_variant_group.title, pvi.title, pvi.amount])
      end
    else
      prices=[]
      product_variant_items.includes{product_variant_group}.map do |pvi|
        prices<<{variantable_title: pvi.product_variant_group.variantable(Certificate).title,
                 pvg_title: pvi.product_variant_group.title, pvi_title: pvi.title, pvi_amount: pvi.amount}
      end
    end
    prices
  end

  def pvi_prices_hash
    prices={}
    product_variant_items.includes{product_variant_group}.map do |pvi|
      prices.merge!(pvi.id => pvi.amount)
    end
    prices
  end

  # to update prices call ResellerTier#prices_matrix and then load that hash as `options` parameter
  # see sample tier creating at the bottom of file
  def update_prices(options)
    options.each {|k,v|
      if k.is_a?(Hash)
        product_variant_items.where{(title==k[:pvi_title]) &
            (product_variant_groups.title==k[:pvg_title])}.find{|pvi|
          pvi.product_variant_group.variantable(Certificate).title==k[:variantable_title]}.
            update_column :amount, k[:pvi_amount]
      else
        if options[:index]
          product_variant_items.find(k).update_column :amount, v.last
        else
          product_variant_items.where{(title==v[2]) &
              (product_variant_groups.title==v[1])}.find{|pvi|
            pvi.product_variant_group.variantable(Certificate).title==v[0]}.
              update_column :amount, v[3]
        end
      end
    }
  end
end


