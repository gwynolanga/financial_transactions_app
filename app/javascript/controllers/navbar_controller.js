import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["links", "innerMenu"];

    toggle() {
        this.linksTarget.classList.toggle("hidden");
    }

    dropdown(event) {
        event.preventDefault();

        if (this.hasInnerMenuTarget) {
            this.innerMenuTarget.classList.toggle("hidden");
        }
    }
}
