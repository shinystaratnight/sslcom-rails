import { Controller } from 'stimulus'
import Tether from 'tether'
import Popper from 'popper.js'

export default class extends Controller {
  static targets = ['parent', 'menu']

  connect() {
    this.toggleClass = this.data.get('class') || 'hidden'

    this._popper = new Popper(this.parentTarget, this.menuTarget, { 
      placement: 'bottom-end',
      scroll: true,
      resize: true
    })
  }

  toggle() {
    this.menuTarget.classList.toggle(this.toggleClass)
    this.menuTarget.classList.toggle("open")
    this._popper.update()
  }

  hide(event) {
    if (
      this.element.contains(event.target) === false &&
      !this.menuTarget.classList.contains(this.toggleClass)
    ) {
      this.menuTarget.classList.add(this.toggleClass)
      this.parentTarget.classList.toggle("open")
    }
  }
}
