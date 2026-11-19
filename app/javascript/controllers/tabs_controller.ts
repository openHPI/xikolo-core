import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['tab', 'panel'];
  static classes = ['active'];

  declare readonly tabTargets: HTMLButtonElement[];
  declare readonly panelTargets: HTMLElement[];
  declare readonly activeClass: string;

  connect(): void {
    const initial = this.tabTargets.findIndex(
      (tab) => tab.getAttribute('aria-selected') === 'true',
    );
    this.activate(initial >= 0 ? initial : 0);
  }

  switch(event: Event): void {
    const index = this.tabTargets.indexOf(
      event.currentTarget as HTMLButtonElement,
    );
    if (index >= 0) this.activate(index);
  }

  private activate(activeIndex: number): void {
    this.tabTargets.forEach((tab, index) => {
      const isActive = index === activeIndex;
      tab.classList.toggle(this.activeClass, isActive);
      tab.setAttribute('aria-selected', isActive.toString());
    });
    this.panelTargets.forEach((panel, index) => {
      panel.toggleAttribute('hidden', index !== activeIndex);
    });
  }
}
