import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["immediate", "scheduled", "deposit", "withdrawal"];

    connect() {
        this.resetRadioButtons();
    }

    toggle(event) {
        const selectedType = event.target.value;
        const targets = {
            immediate: this.immediateTarget,
            scheduled: this.scheduledTarget,
            deposit: this.depositTarget,
            withdrawal: this.withdrawalTarget,
        };

        Object.entries(targets).forEach(([type, target]) => {
            const isHidden = selectedType !== type;

            target.classList.toggle("hidden", isHidden);

            if (isHidden) {
                this.clearInputs(target);
            } else {
                this.setFocus(target);
            }
        });
    }

    clearInputs(target) {
        target.querySelectorAll("label").forEach((label) => label.classList.remove("error"));

        target.querySelectorAll("input, textarea, select").forEach((input) => {
            if (input.type === "checkbox" || input.type === "radio") {
                input.checked = false;
            } else {
                input.value = "";
            }

            input.classList.remove("error");

            const errorMessage = input.nextElementSibling;
            if (errorMessage && errorMessage.classList.contains("form-error-messages")) {
                errorMessage.textContent = "";
            }
        });
    }

    resetRadioButtons() {
        const radioButtons = this.element.querySelectorAll('input[type="radio"][name="transaction[kind]"]');
        if (radioButtons.length === 0) return;

        const firstRadio = Array.from(radioButtons).find((radio) => radio.checked) || radioButtons[0];
        if (firstRadio) {
            firstRadio.checked = true;
            firstRadio.dispatchEvent(new Event("change"));
        }
    }

    setFocus(target) {
        const firstInput = target.querySelector("input:not([disabled]), textarea:not([disabled]), select:not([disabled])");
        firstInput?.focus();
    }
}
