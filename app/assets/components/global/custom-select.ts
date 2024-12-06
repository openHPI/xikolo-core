/**
 * TomSelect initializer
 *
 * Usage: add data-behavior='custom-select' to the input.
 *
 * Refer to the Lookbook documentation (http://localhost:3000/rails/components/inspect/util/custom_select/advanced_options)
 * for all available settings and configuration instructions.
 * For custom implementations, add and import overrides from './custom-select/' and include them to the settings object.
 *
 * For more information, check out TomSelect docs: https://tom-select.js.org/
 *
 */

import TomSelect from 'tom-select/dist/esm/tom-select.complete';
import { TomInput } from 'tom-select/dist/esm/types';
import ready from '../../util/ready';
import * as settings from './custom-select/settings';
import getClassifiersSettings from './custom-select/classifiers-select';
import getItemStatsSettings from './custom-select/item-stats-select';

export function tomSelectSettings(select: TomInput) {
  return {
    ...settings.getBasic(),

    // Add advanced settings according to attributes
    ...(select.hasAttribute('multiple') && settings.getMultipleSelect()),
    ...(select.dataset.autoCompletionUrl && settings.getRemoteLoad(select)),
    ...(select.dataset.preload && settings.preload),
    ...(select.dataset.autoCompletionUrl &&
      !select.dataset.preload &&
      settings.getDelayedLoad()),
    ...(select.dataset.create && settings.getCreateOptions()),
    ...(select.dataset.prefix && settings.getPrefill(select)),
  };
}

export function initializeTomSelect(scope: Document | HTMLElement = document) {
  const selectInputs = scope.querySelectorAll<TomInput>(
    '[data-behavior="custom-select"]',
  );

  selectInputs.forEach((select: TomInput) => {
    // eslint-disable-next-line no-new
    new TomSelect(select, {
      ...tomSelectSettings(select),
      // Custom settings for specific implementation
      ...(select.dataset.cluster && getClassifiersSettings(select)),
      ...(select.dataset.redirect && getItemStatsSettings()),
    });
  });
}

ready(() => {
  initializeTomSelect();
});
