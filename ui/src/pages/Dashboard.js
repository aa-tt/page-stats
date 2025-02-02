import React, { useState } from 'react';
import RegionSelector from '../components/RegionSelector';
import DateSelector from '../components/DateSelector';

const Dashboard = () => {
  const [region, setRegion] = useState('us-west');
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [data, setData] = useState([]);

  const fetchData = async () => {
    const hostname = window.location.hostname;
    const port = window.location.port ? `:${window.location.port}` : '';
    const protocol = window.location.protocol;
    const apiUrl = `${protocol}//${hostname}${port}/api/aggregated-data/region-weekly?region=${region}&startTime=${startTime}&endTime=${endTime}`;

    const response = await fetch(apiUrl);
    const result = await response.json();
    setData(result);
  };

  return (
    <div>
      <h1>Dashboard</h1>
      <RegionSelector region={region} setRegion={setRegion} />
      <div>
        <label>Start Time: </label>
        <DateSelector date={startTime} setDate={setStartTime} />
      </div>
      <div>
        <label>End Time: </label>
        <DateSelector date={endTime} setDate={setEndTime} />
      </div>
      <button onClick={fetchData}>Fetch Data</button>
      <ul>
        {data.map((item, index) => (
          <li key={index}>{item.pageName}: {item.visits}</li>
        ))}
      </ul>
    </div>
  );
};

export default Dashboard;