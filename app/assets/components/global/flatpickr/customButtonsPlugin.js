function CustomButtonsPlugin() {
  return (fp) => {
    // We use a native date time picker on mobile, so no need to extend it
    if (fp.isMobile) return {};

    return {
      onReady() {
        const buttonContainer = document.createElement('div');
        buttonContainer.classList.add('flatpickr-calendar__custom-buttons');

        // Clear button will clear the input value
        const clearButton = document.createElement('button');
        clearButton.type = 'button';
        clearButton.innerHTML = '<i class="fa-regular fa-trash-can"></i>';
        clearButton.ariaLabel = I18n.t('components.date_time_picker.clear');
        clearButton.title = I18n.t('components.date_time_picker.clear');
        clearButton.addEventListener('click', fp.clear);

        // Today button set today's day, but keeps the previously entered time
        const todayButton = document.createElement('button');
        todayButton.type = 'button';
        todayButton.innerHTML = '<i class="fa-regular fa-calendar-day"></i>';
        todayButton.ariaLabel = I18n.t('components.date_time_picker.today');
        todayButton.title = I18n.t('components.date_time_picker.today');
        todayButton.addEventListener('click', () => {
          const today = new Date();
          today.setHours(
            fp.latestSelectedDateObj
              ? fp.latestSelectedDateObj.getHours()
              : fp.config.defaultHour,
          );
          today.setMinutes(
            fp.latestSelectedDateObj
              ? fp.latestSelectedDateObj.getMinutes()
              : fp.config.defaultMinute,
          );
          today.setSeconds(0);
          fp.setDate(today);
        });

        fp.calendarContainer.appendChild(buttonContainer);
        buttonContainer.appendChild(todayButton);
        buttonContainer.appendChild(clearButton);

        fp.loadedPlugins.push('customButtons');
      },
    };
  };
}

export default CustomButtonsPlugin;
