import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    to(e) {
        e.preventDefault();
        const { url } = e.target.dataset;
        this.element.src = url;
        history.pushState(null, null, url);
    }
}
