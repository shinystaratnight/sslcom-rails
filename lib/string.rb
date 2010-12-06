class String
  # Return an alternate string if blank.
  def or_else(alternate)
    blank? ? alternate : self
  end
  
  # Capitalize each word (space separated).
  def capitalize_each
    space = " "
    split(space).each{ |word| word.capitalize! }.join(space)
  end
  
  # Capitalize each word in place.
  def capitalize_each!
    replace capitalize_each
  end
  
  def shorten (count = 10, word_boundary = true)
    if word_boundary
      if self.length >= count
        shortened = self[0, count]
        splitted = shortened.split(/\s/)
        words = splitted.length
        splitted[0, words-1].join(" ") + ' ...'
      else
        self
      end
    else
      if length >= count
        self[0, count-4] << ' ...'
      else
        self
      end
    end
  end

  def urlencode
    gsub( /[^a-zA-Z0-9\-_\.!~*'()]/n ) {|x| sprintf('%%%02x', x[0]) }
  end

end