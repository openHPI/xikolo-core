import { Controller, type ActionEvent } from '@hotwired/stimulus';
import type { HlsJsVideoElement } from '@videojs/html/media/hlsjs-video';
import handleError from '../../util/error';

export type SelectionEvent = CustomEvent<{
  index: number;
}>;

// The playlist tracks original items independently of carousel clones.
export default class extends Controller<HTMLElement> {
  static targets = ['item', 'dialog', 'video'];

  declare readonly itemTargets: HTMLButtonElement[];
  declare readonly dialogTarget: HTMLDialogElement;
  declare readonly videoTarget: HlsJsVideoElement;

  private playingIndex = 0;

  open(event: ActionEvent) {
    this.playingIndex = event.params.index;
    this.playItem();
    this.dialogTarget.showModal();
  }

  previousVideo() {
    this.playAdjacent(-1);
  }

  nextVideo() {
    this.playAdjacent(1);
  }

  close() {
    this.videoTarget.pause();
    this.dispatch('close');
  }

  private playAdjacent(direction: -1 | 1) {
    const count = this.itemTargets.length;
    this.playingIndex = (this.playingIndex + direction + count) % count;
    this.playItem();
    this.dispatch('select', { detail: { index: this.playingIndex } });
  }

  private async playItem() {
    const videoSrc = this.itemTargets[this.playingIndex]?.dataset.videoSrc;
    if (!videoSrc) return;

    try {
      this.videoTarget.src = new URL(videoSrc, window.location.href).href;
      // Let the custom video element process the changed source before play().
      await Promise.resolve();
      await this.videoTarget.play();
    } catch (error) {
      handleError(undefined, error, false);
    }
  }
}
