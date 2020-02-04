# frozen_string_literal: true

Paperclip.options[:content_type_mappings] = {
  mp3: 'application/octet-stream',
  m4a: %w[video/mp4],
  jpg: 'image/jpeg',
  png: 'image/png',
  gif: 'image/gif'
}
