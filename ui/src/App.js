import React, { useState } from 'react';
import { BrowserRouter as Router, Route, Link, Routes } from 'react-router-dom';
import HomePage from './pages/HomePage';
import AboutPage from './pages/AboutPage';
import ContactPage from './pages/ContactPage';
import PageX from './pages/PageX';
import PageY from './pages/PageY';
import PageZ from './pages/PageZ';
import Dashboard from './pages/Dashboard';
import RegionSelector from './components/RegionSelector';
import DateSelector from './components/DateSelector';
import Tracker from './components/Tracker';

const App = () => {
  const [region, setRegion] = useState('us-west');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);

  return (
    <Router>
      <div>
        <nav>
          <ul>
            <li><Link to="/">Home</Link></li>
            <li><Link to="/about">About</Link></li>
            <li><Link to="/contact">Contact</Link></li>
            <li><Link to="/pagex">Page X</Link></li>
            <li><Link to="/pagey">Page Y</Link></li>
            <li><Link to="/pagez">Page Z</Link></li>
            <li><Link to="/dashboard">Dashboard</Link></li>
          </ul>
        </nav>
        <RegionSelector region={region} setRegion={setRegion} />
        <DateSelector date={date} setDate={setDate} />
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/about" element={<AboutPage />} />
          <Route path="/contact" element={<ContactPage />} />
          <Route path="/pagex" element={<PageX />} />
          <Route path="/pagey" element={<PageY />} />
          <Route path="/pagez" element={<PageZ />} />
          <Route path="/dashboard" element={<Dashboard />} />
        </Routes>
        <Tracker region={region} timestamp={date} />
      </div>
    </Router>
  );
};

export default App;