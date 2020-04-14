module AffiliatesHelper
  def build_affiliate_links
    @photos_count = @affiliate.photos.count
    @posts_count = @affiliate.posts.count
    @affiliate_links = affiliate_links
  end

  def affiliate_links
    link_to("Images (#{@photos_count})".l, affiliate_affiliate_photos_path(@affiliate)) + " \&#8226; " +
      link_to("Blog Postings (#{@posts_count})".l, affiliate_posts_path(@affiliate))
  end

  def affiliate_photos
    ((link_to("Images (#{@photos_count})".l, affiliate_affiliate_photos_path(@affiliate)) + (@posts_count > 0 ? " \&#8226; " : ' ')) if
    @photos_count > 0) || ''
  end

  def affiliate_blogs
    (link_to("Blog Postings (#{@posts_count})".l, affiliate_posts_path(@affiliate)) if @posts_count > 0) || ''
  end
end
