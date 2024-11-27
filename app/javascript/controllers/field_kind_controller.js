import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["kind", "executionDate"];

    connect() {
        this.toggleExecutionDate();
    }

    toggleExecutionDate() {
        const kindValue = this.kindTarget.value;

        if (kindValue === "scheduled") {
            this.executionDateTarget.removeAttribute("disabled");
        } else if (kindValue === "immediate") {
            this.executionDateTarget.value = "";
            this.executionDateTarget.setAttribute("disabled", "true");
        }
    }
}
