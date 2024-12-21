"use client";

import { useState } from "react";
import { SparklesCore } from "../components/ui/sparkles";

export default function Home() {
  const [formData, setFormData] = useState({
    telegram: "",
    twitter: "",
    address: "",
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const response = await fetch('/api/whitelist', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });
      
      if (response.ok) {
        alert('Successfully whitelisted!');
        setFormData({ telegram: "", twitter: "", address: "" });
      } else {
        alert('Error submitting whitelist entry');
      }
    } catch (error) {
      console.error('Error:', error);
      alert('Error submitting whitelist entry');
    }
  };

  return (
    <main className="min-h-screen bg-black text-white p-4">
      <div className="max-w-4xl mx-auto pt-20">
        <div className="relative mb-20">
          <h1 className="text-5xl font-bold text-center mb-2">
            Coming to Berachain in Q5
          </h1>
          <div className="absolute inset-x-0 -bottom-8">
            <SparklesCore
              background="transparent"
              minSize={0.4}
              maxSize={1}
              particleDensity={100}
              className="w-full h-20"
              particleColor="#FFA500"
            />
          </div>
        </div>

        <form onSubmit={handleSubmit} className="max-w-md mx-auto space-y-6 mt-20">
          <div>
            <label className="block text-sm font-medium mb-2">Telegram</label>
            <input
              type="text"
              value={formData.telegram}
              onChange={(e) => setFormData({ ...formData, telegram: e.target.value })}
              className="w-full px-4 py-2 bg-gray-800 rounded-lg focus:ring-2 focus:ring-honey"
              required
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-2">Twitter</label>
            <input
              type="text"
              value={formData.twitter}
              onChange={(e) => setFormData({ ...formData, twitter: e.target.value })}
              className="w-full px-4 py-2 bg-gray-800 rounded-lg focus:ring-2 focus:ring-honey"
              required
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-2">Wallet Address</label>
            <input
              type="text"
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              className="w-full px-4 py-2 bg-gray-800 rounded-lg focus:ring-2 focus:ring-honey"
              required
            />
          </div>

          <button
            type="submit"
            className="w-full py-3 px-4 bg-honey hover:bg-honey-dark text-black font-bold rounded-lg transition-colors"
          >
            Whitelist
          </button>
        </form>
      </div>
    </main>
  );
} 