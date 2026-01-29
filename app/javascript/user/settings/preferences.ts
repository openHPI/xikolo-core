import ready from '../../util/ready';
import fetch from '../../util/fetch';

const emailNotificationEnabled = () => {
  const globalEmailPreferenceToggle = document.querySelector(
    '#preferences-notification-email-global',
  ) as HTMLInputElement;

  return globalEmailPreferenceToggle.checked;
};

ready(() => {
  document
    .querySelectorAll('[data-behavior="preferences-switch"]')
    .forEach((preferencesSwitch) => {
      preferencesSwitch.addEventListener('change', async (event) => {
        try {
          const target = event.target as HTMLInputElement;

          const formData = new FormData();
          formData.append('name', target.name);
          formData.append('value', target.checked.toString());

          const response = await fetch('/preferences', {
            method: 'PUT',
            body: formData,
          });

          if (!response.ok) {
            throw new Error(response.statusText);
          }

          const notificationPreferencesAvailable = document.querySelector(
            "[data-toggle-notification-preferences='true']",
          );

          const notificationPreferences = document.querySelector(
            '#notification-preferences',
          );

          if (notificationPreferencesAvailable && notificationPreferences) {
            if (emailNotificationEnabled()) {
              notificationPreferences.removeAttribute('hidden');
            } else {
              notificationPreferences.setAttribute('hidden', 'true');
            }
          }
        } catch (error) {
          console.error('Error saving preferences:', error);
        }
      });
    });
});
