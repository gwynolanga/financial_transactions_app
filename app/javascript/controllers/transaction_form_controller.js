import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["transactionKindRadios", "transactionFields"];

    connect() {
        // After refreshing the page in the browser by pressing the F5 key on the keyboard
        window.addEventListener('load', this.resetForm.bind(this));
    }

    visitUrl(event) {
        const url = event.target.dataset.url;
        const turboFrame = event.target.dataset.turboFrame;

        if (url && turboFrame) {
            const frame = document.getElementById(turboFrame);
            if (frame) {
                frame.src = url;
                window.history.pushState({}, "", url);
            }
        }
    }

    resetForm() {
        const radios = this.transactionKindRadiosTarget.querySelectorAll('input');
        const fields = this.transactionFieldsTarget.querySelectorAll('input, select, textarea');

        radios.forEach(radio => {
            radio.checked = radio.dataset.default === "true"
        });

        fields.forEach(field => {
            field.value = field.dataset.default;
        });
    }
}
