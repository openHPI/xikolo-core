/**
 * An interactive transcript component
 *
 * Provide the DOM element by rendering the Transcript view component with
 * its initial hidden state:
 *    E.g:  Transcript.new(true)
 * Optional configurations are the empty state message and the "scroll to
 * position" button text:
 *    E.g:  Transcript.new(true, empty_msg: 'No data available', scroll_button_text: 'Scroll to current position')
 *
 * Initialize the transcript component passing in the video player element
 * and react to its events with the available transcript methods:
 *    E.g: const transcript = new Transcript(videoWithTranscript);
 */

const scrollingModes = {
  MANUAL: 'manual',
  AUTOMATIC: 'automatic',
  RESTORE_AUTOMATIC: 'restoreAutomatic',
};

const formatTime = (seconds) => {
  const totalSecs = Math.trunc(seconds);
  const h = Math.floor(totalSecs / 3600);
  const m = Math.floor(totalSecs / 60) % 60;
  const s = totalSecs % 60;

  return [h, m, s]
    .map((value) => (value < 10 ? `0${value}` : value))
    .filter((value, i) => value !== '00' || i > 0)
    .join(':');
};

const centerOfCues = (cues, container) =>
  cues[0].offsetTop -
  container.offsetTop -
  (container.clientHeight - cues[0].clientHeight * cues.length) * 0.5;

const setCueStyle = (cue, style) => {
  switch (style) {
    case 'active':
      cue.setAttribute('aria-current', 'true');
      cue.setAttribute('tabindex', 0);
      break;
    case 'inactive':
      cue.removeAttribute('aria-current');
      cue.setAttribute('tabindex', -1);
      break;
    default:
  }
};

export default class Transcript {
  constructor(htmlElement) {
    this.element = htmlElement;

    this.transcript = this.element.querySelector('[data-transcript]');
    this.cueList = this.transcript.querySelector('[data-transcript-cues]');
    this.cueList.addEventListener('scroll', (e) => this.scrollLogic(e));
    this.cueList.addEventListener('click', (e) => this.seekCue(e));
    this.infoMessage = this.transcript.querySelector(
      '[data-transcript-message]',
    );
    this.scrollIndicator = this.transcript.querySelector(
      '[data-transcript-indicator]',
    );
    this.scrollIndicator.addEventListener('click', () =>
      this.restoreAutomaticScrolling(),
    );

    // Allow navigating through the cues with the arrow keys (when the cue list is focused).
    // Use enter to jump to / start from the selected cue
    this.cueList.addEventListener('keydown', (e) => {
      let currentFocusedCues = this.transcript.querySelector(':focus');
      switch (e.code) {
        case 'ArrowUp':
          e.preventDefault();
          currentFocusedCues = currentFocusedCues.previousElementSibling;
          if (currentFocusedCues) {
            currentFocusedCues.focus();
          }
          break;
        case 'ArrowDown':
          e.preventDefault();
          currentFocusedCues = currentFocusedCues.nextElementSibling;
          if (currentFocusedCues) {
            currentFocusedCues.focus();
          }
          break;
        case 'Enter':
          this.seekCue(e);
          break;
        default:
          break;
      }
    });

    this.icon = this.transcript.querySelector('[data-transcript-icon]');
    this.scrollingMode = scrollingModes.AUTOMATIC;
    this.userHasScrolled = false;
    this.lastAutomaticScrollPosition = this.cueList.scrollTop;
    this.cues = [];
    this.activeCues = [];
  }

  /*
   * Show/hide the transcript component
   */
  toggleVisibility(active) {
    this.transcript.hidden = !active;
  }

  /*
   * Fill the transcript with the cues information
   * expected cue format: {identifier:'1', start: 5.8, end: 11.9. text: 'Welcome to this video'}
   */
  fill(cues) {
    this.cueList.innerHTML = ''; // Reset content
    this.cues = cues;
    this.cues.forEach((cue, i) => {
      const newCue = document.createElement('li');
      const cueTime = document.createElement('span');
      const startTime = formatTime(cue.start);

      cueTime.textContent = startTime;
      cueTime.classList.add('transcript__start-time');
      newCue.textContent = cue.text;
      newCue.setAttribute('role', 'button');
      newCue.setAttribute('tabindex', -1);
      newCue.setAttribute('data-start-time', cue.start);
      newCue.setAttribute('data-id', cue.identifier);
      newCue.prepend(cueTime);
      this.cueList.appendChild(newCue);

      // Always highlight the first cue by default: In some WebVTT files
      // the first cue could start at 00:03. If there is no active cue
      // the transcript can not use keyboard navigation.
      if (i === 0) {
        this.activeCues = [newCue];
        setCueStyle(newCue, 'active');
      }
    });
    this.displayInfoMessage(false);
  }

  /*
   * Show/hide the transcript component
   */
  displayInfoMessage(state) {
    this.infoMessage.hidden = !state;
  }

  /*
   * Highlight the current active cue/s
   */
  updateActiveCues(cues) {
    // Unhighlight previously highlighted cues
    if (this.activeCues) {
      this.activeCues.forEach((cue) => setCueStyle(cue, 'inactive'));
    }
    // Find cues in transcirpt's cue list
    this.activeCues = cues
      .map((activeCue) =>
        this.cueList.querySelector(`[data-id="${activeCue.identifier}"]`),
      )
      .filter((activeCues) => activeCues != null);
    // Apply highlight style
    this.activeCues.forEach((cue) => setCueStyle(cue, 'active'));
    // Scroll transcript to center active cues
    this.scrollLogic();
  }

  scrollLogic() {
    // Compare transcript's scroll position with its last position when a scroll was automatically triggered
    // If different, it means the user manually scrolled
    this.userHasScrolled =
      this.cueList.scrollTop !== this.lastAutomaticScrollPosition;

    if (this.userHasScrolled) {
      this.setUpIndicators();
    } else {
      this.scrollIndicator.classList.add('blank');
    }

    switch (this.scrollingMode) {
      case scrollingModes.AUTOMATIC:
        if (this.userHasScrolled) {
          this.scrollingMode = scrollingModes.MANUAL;
        } else {
          this.cueList.scrollTop = centerOfCues(this.activeCues, this.cueList);
          this.lastAutomaticScrollPosition = this.cueList.scrollTop;
        }
        break;

      case scrollingModes.RESTORE_AUTOMATIC:
        this.cueList.scrollTop = centerOfCues(this.activeCues, this.cueList);
        this.lastAutomaticScrollPosition = this.cueList.scrollTop;
        this.scrollingMode = scrollingModes.AUTOMATIC;
        break;

      case scrollingModes.MANUAL:
        // Prevent user manually synicing with the last automatic scroll position
        this.lastAutomaticScrollPosition = null;
        break;

      default:
        break;
    }
  }

  restoreAutomaticScrolling() {
    this.scrollingMode = scrollingModes.RESTORE_AUTOMATIC;
    this.scrollLogic();
  }

  setUpIndicators() {
    if (this.cueList.scrollTop > centerOfCues(this.activeCues, this.cueList)) {
      this.scrollIndicator.classList.remove('blank', 'bottom');
      this.scrollIndicator.classList.add('top');
      this.icon.classList.remove('fa-arrow-down');
      this.icon.classList.add('fa-arrow-up');
    } else {
      this.scrollIndicator.classList.remove('blank', 'top');
      this.scrollIndicator.classList.add('bottom');
      this.icon.classList.remove('fa-arrow-up');
      this.icon.classList.add('fa-arrow-down');
    }
  }

  /*
   * Emit a custom 'transcript:seeked' event when a cue is clicked, containing
   * its start time. Useful to react accordingly by seeking the provided start time in the player
   * with its corresponding API. It also highlights and centers the cue.
   */
  seekCue(e) {
    const targetElement = e.target.closest('[data-start-time]');
    const startTimeClickedCue = targetElement.getAttribute('data-start-time');
    this.element.dispatchEvent(
      new CustomEvent('transcript:seeked', {
        detail: {
          seconds: startTimeClickedCue,
        },
      }),
    );
    this.scrollingMode = scrollingModes.RESTORE_AUTOMATIC;
  }
}
