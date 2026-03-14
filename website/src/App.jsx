import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Footer from './components/Footer';
import Home from './pages/Home';
import Features from './pages/Features';
import Architecture from './pages/Architecture';
import Flow from './pages/Flow';
import Download from './pages/Download';

export default function App() {
    return (
        <BrowserRouter>
            <Navbar />
            <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/features" element={<Features />} />
                <Route path="/architecture" element={<Architecture />} />
                <Route path="/flow" element={<Flow />} />
                <Route path="/download" element={<Download />} />
            </Routes>
            <Footer />
        </BrowserRouter>
    );
}
