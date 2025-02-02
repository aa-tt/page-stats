import React, { useEffect } from 'react';
import { useLocation } from 'react-router-dom';

const Tracker = ({ region, timestamp }) => {
  const location = useLocation();

  useEffect(() => {
    const pageName = location.pathname.replace('/', '') || 'HomePage';
    const hostname = window.location.hostname;
    const port = window.location.port ? `:${window.location.port}` : '';
    const protocol = window.location.protocol;
    const apiUrl = `${protocol}//${hostname}${port}/api/page-view`;

    async function sendPageViewEvent() {
      const event = {
        pageName: pageName,
        region: region,
        timestamp: timestamp
      };

      try {
        const response = await fetch(apiUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(event)
        });

        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
      } catch (error) {
        console.error('There was a problem with the fetch operation:', error);
      }
    }

    sendPageViewEvent();
  }, [location, region, timestamp]);

  return null;
};

export default Tracker;