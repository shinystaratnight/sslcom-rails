import "../stylesheets/index.css.scss"

window.Rails = require("@rails/ujs")

require("turbolinks").start()
require("jquery")
require("chartkick")
require("chart.js")
require("velocity-animate")
require("../src/theme")

require.context("../images", true)

Rails.start()
