import lanalyticsTrack from '../../legacy/lanalytics/common';

const RESOURCE_TYPE = 'video';

export default class PlayerTracker {
  constructor() {
    /**
     * This state will be always tracked and send to lanalytics.
     */
    this.playerState = {
      currentTime: 0,
      currentSpeed: 1,
      currentFullscreen: false,
      playerVersion: 'video-player',
      course_id: gon.course_id,
      section_id: gon.section_id,
    };
    /**
     * This state is needed for special cases for lanalytics tracking events.
     * It saves the state for further working or conditions.
     */
    this.privatePlayerState = {
      isTranscriptActive: false,
    };
  }

  updateTime(seconds) {
    this.playerState.currentTime = seconds;
  }

  /**
   * Updates the current time of the player state and dispatches
   * a track event with these state data.
   * @param {string} verb
   * @param {number} seconds
   */
  trackTime(verb, seconds) {
    this.updateTime(seconds);
    PlayerTracker.trackEvent(verb, this.playerState);
  }

  /**
   * Updates the current time of the player state after dispatching
   * a track event with the state data and these 2 time properties: newCurrentTime, oldCurrentTime.
   * @param {string} verb
   * @param {number} seconds
   */
  trackTimeWhileSeeking(verb, seconds) {
    const eventState = { ...this.playerState };
    delete eventState.currentTime;
    PlayerTracker.trackEvent(verb, {
      ...eventState,
      oldCurrentTime: this.playerState.currentTime,
      newCurrentTime: seconds,
    });
    this.updateTime(seconds);
  }

  /**
   * Updates a property with the given property name of the player state after dispatching
   * a track event with the state data and the new property name.
   * @param {sring} verb
   * @param {string} newPropertyName new property name for lanalytics
   * @param {strng} propertyName original property name
   * @param {any} value
   */
  trackProperty(verb, newPropertyName, propertyName, value) {
    const eventState = { ...this.playerState, [newPropertyName]: value };
    delete eventState[propertyName];
    PlayerTracker.trackEvent(verb, eventState);
    this.playerState[propertyName] = value;
  }

  /**
   * Dispatches a track event with the given lanalytics verb and the player state
   * or the event state.
   * @param {string} verb
   * @param {Object} context
   */
  static trackEvent(verb, context) {
    /* global gon */
    /* eslint no-undef: "error" */
    if (gon.user_id !== undefined && gon.item_id !== undefined) {
      lanalyticsTrack(verb, gon.item_id, RESOURCE_TYPE, context);
    }
  }
}
