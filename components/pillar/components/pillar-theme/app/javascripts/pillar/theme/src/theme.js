require("./libs/confirm")

import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"
import { Dropdown, NestedForm } from "./components"
import Tether from "tether"

const application = Application.start()
const context = require.context("./components/controllers", true, /.js$/)
application.load(definitionsFromContext(context))


$(document).on("turbolinks:load", function() {

  application.register('dropdown', Dropdown)
  application.register('nested-form', NestedForm)
  
  //
  // FLASH MESSAGES
  //

  const close_flash_message = (target_selector) => {
    console.log("Close flash message: " + target_selector)
    const target_element = $(target_selector)
    const target_width = -Math.abs(target_element.width() + 50)

    Velocity(target_element, {
      right: target_width
    }, {
      duration: 250,
      easing: "linear",
      complete: () => {
        $(target_element).remove()
      }
    })
  }

  $("a.trigger").on("click", function(event) {
    close_flash_message($(event.target).closest(".flash-message"))
  })

  if($(".flash-message").length) {
    setTimeout(() => {
      close_flash_message(".flash-message")
    }, 3500)
  }
})
