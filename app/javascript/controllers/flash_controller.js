// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    dismiss() {
        this.element.remove();
    }

    connect() {
        setTimeout(() => this.dismiss(), 7000);
    }
}
