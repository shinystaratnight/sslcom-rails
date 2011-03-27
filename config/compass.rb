# This configuration file works with both the Compass command line tool and within Rails.
# Require any additional compass plugins here.
project_type = :rails
# Set this to the root of your project when deployed:
http_path = "/"
css_dir = "public/stylesheets/compiled"
http_stylesheets_path = "/stylesheets"
sass_dir = "app/stylesheets"
images_dir = "public/images"
http_images_path = "/images"
javascripts_dir = "public/javascripts"
http_javascripts_path = "/javascripts"
sass_options = {line_numbers: true, style: :expanded, never_update: false}
#sass_options = {debug_info: true, style: :expanded} #use when firesass works for firebug 1.6
#sass_options = {style: :compressed} #for production use
# You can select your preferred output style here (can be overridden via the command line):
# output_style = :expanded or :nested or :compact or :compressed
# To enable relative paths to assets via compass helper functions. Uncomment:
# relative_assets = true

# If you prefer the indented syntax, you might want to regenerate this
# project again passing --syntax sass, or you can uncomment this:
# preferred_syntax = :sass
# and then run:
# sass-convert -R --from scss --to sass app/stylesheets scss && rm -rf sass && mv scss sass
