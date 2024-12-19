import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["links", "innerMenu"];

    // Fix a weird behaviour after redirecting to another page
    disconnect() {
        if (this.hasInnerMenuTarget) {
            this.innerMenuTarget.remove();
        }
    }

    toggle() {
        this.linksTarget.classList.toggle("hidden");
    }

    openDropdown(event) {
        event.preventDefault();

        if (this.hasInnerMenuTarget) {
            this.innerMenuTarget.classList.toggle("hidden");
        }
    }

    // Close the innerMenu target by LMB clicking outside of that target
    closeDropdown(event) {
        if (!this.element.contains(event.relatedTarget)) {
            this.innerMenuTarget.classList.add("hidden");
        }
    }
}
