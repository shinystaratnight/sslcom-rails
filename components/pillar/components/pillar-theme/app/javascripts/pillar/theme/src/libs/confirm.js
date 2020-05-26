const Rails = require("@rails/ujs")
const old_confirm = Rails.confirm;
const elements = ['a[data-confirm]', 'button[data-confirm]', 'input[type=submit][data-confirm]']

const createConfirmModal = (element) => {
  var id = 'confirm-modal-' + String(Math.random()).slice(2, -1);
  var confirm = element.dataset.confirm
  var message = JSON.parse(element.dataset.confirm)

  var content = `
    <div class="backdrop-container" id="${id}">
      <div class="backdrop"></div>
      <div class="modal">
        <a class="close" data-behavior="close">
          <i class="fal fa-times-circle text-3xl"></i>
        </a>
        <div class="content">
          <div class="text-white text-4xl font-bold mb-2 uppercase">
            <i class="fas fa-exclamation-triangle text-6xl text-yellow-200"></i>
          </div>
          <div class="text-white text-4xl font-bold mb-2 uppercase">
            ${message.title}
          </div>
          <div class="text-gray-300 text-xl font-light mb-6">
          ${message.subtitle}
          </div>
          <div class="flex items-center justify-center">
            <button data-behavior="cancel" class="btn lg red mr-6 w-24 focus:outline-none">No</button>
            <button data-behavior="commit" class="btn lg primary w-24 focus:outline-none">Yes</button>
          </div>
        </div>
      </div>
    </div>
  `

  $("body").append(content)

  var modal = document.getElementById(id)
  element.dataset.confirmModal = `#${id}`

  modal.addEventListener("keyup", (event) => {
    if(event.key === "Escape") {
      event.preventDefault()
      element.removeAttribute("data-confirm-modal")
      modal.remove()
    }
  })

  modal.querySelector("[data-behavior='cancel']").addEventListener("click", (event) => {
    event.preventDefault()
    element.removeAttribute("data-confirm-modal")
    modal.remove()
  })

  modal.querySelector("[data-behavior='close']").addEventListener("click", (event) => {
    event.preventDefault()
    element.removeAttribute("data-confirm-modal")
    modal.remove()
  })

  modal.querySelector("[data-behavior='commit']").addEventListener("click", (event) => {
    event.preventDefault()
    Rails.confirm = () => { return true }
    element.click()
    element.removeAttribute("data-confirm-modal")
    Rails.confirm = old_confirm
    modal.remove()
  })

  modal.querySelector("[data-behavior='commit']").focus()

  return modal
}

const confirmModalOpen = (element) => {
  return !!element.dataset.confirmModal;
}

const handleConfirm = (event) => {
  if (confirmModalOpen(event.target)) {
    return true
  } else {
    createConfirmModal(event.target)
    return false
  }
}

Rails.delegate(document, elements.join(', '), 'confirm', handleConfirm)
