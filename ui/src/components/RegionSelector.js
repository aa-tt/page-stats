import React from 'react';

const RegionSelector = ({ region, setRegion }) => {
  return (
    <select value={region} onChange={(e) => setRegion(e.target.value)}>
      <option value="us-west">US West</option>
      <option value="us-east">US East</option>
      <option value="asia-south">Asia South</option>
      <option value="asia-north">Asia North</option>
    </select>
  );
};

export default RegionSelector;