import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

export default class extends Controller {
    connect() {
        this.picker = flatpickr(this.element, {
            disableMobile: "true", // Fix a weird behaviour (broken datepicker) for mobile screen size
            enableTime: true,
            dateFormat: "Y-m-d H:i",
            minDate: "today"
        })
    }

    disconnect() {
        this.picker.destroy()
    }
}
