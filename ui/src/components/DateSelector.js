import React from 'react';

const DateSelector = ({ date, setDate }) => {
  return (
    <input
      type="date"
      value={date}
      onChange={(e) => setDate(e.target.value)}
    />
  );
};

export default DateSelector;