"use client";

import { useState } from "react";
import { SparklesCore } from "../components/ui/sparkles";
import Image from "next/image";
import { motion, AnimatePresence } from "framer-motion";
import { TextGenerateEffect } from "../components/ui/text-generate-effect";
import { Modal } from "../components/ui/modal";

export default function Home() {
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    telegram: "",
    twitter: "",
    address: "",
  });
  const [showBeradigmModal, setShowBeradigmModal] = useState(false);
  const [showBElizaModal, setShowBElizaModal] = useState(false);

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
        setShowForm(false);
      } else {
        alert('Error submitting whitelist entry');
      }
    } catch (error) {
      console.error('Error:', error);
      alert('Error submitting whitelist entry');
    }
  };

  return (
    <main className="relative min-h-screen bg-black text-white overflow-hidden">
      {/* Video Background with Blur Overlay */}
      <div className="absolute top-0 left-0 w-full h-full">
        <video
          autoPlay
          loop
          muted
          playsInline
          className="absolute top-0 left-0 w-full h-full object-cover blur-sm"
        >
          <source src="/bg.mp4" type="video/mp4" />
        </video>
        <div className="absolute top-0 left-0 w-full h-full bg-black/50 backdrop-blur-sm"></div>
      </div>

      <div className="relative z-10">
        {/* Navigation Bar */}
        <nav className="fixed top-0 left-0 right-0 p-4 flex justify-between items-center">
          <div className="flex items-center gap-2">
            <motion.h1 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="font-outfit text-2xl font-bold tracking-tight"
            >
              <span className="bg-gradient-to-r from-honey via-orange-400 to-honey bg-clip-text text-transparent">
                baos.fun
              </span>
            </motion.h1>
            <span className="text-2xl">🐻</span>
          </div>
          
          <div className="flex items-center gap-4">
            <a href="https://twitter.com/baosdotfun" target="_blank" rel="noopener noreferrer">
              <Image
                src="/x.png"
                alt="Twitter"
                width={24}
                height={24}
                className="opacity-80 hover:opacity-100 transition-opacity"
              />
            </a>
          </div>
        </nav>

        <AnimatePresence mode="wait">
          {!showForm ? (
            <motion.div
              key="landing"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="min-h-screen flex flex-col items-center p-4"
            >
              <div className="flex-1 flex flex-col items-center justify-center w-full max-w-4xl mx-auto">
                {/* Description */}
                <TextGenerateEffect 
                  words="Raise BERA for your BAO to farm BGT & compete for protocol rewards using AI agents that can farm every Berachain protocol."
                  className="text-2xl text-center max-w-2xl mb-20 leading-relaxed tracking-wide text-white"
                  filter={false}
                  duration={0.8}
                />

                {/* Coming to Berachain Title with Sparkles */}
                <div className="relative mb-32">
                  <motion.h2 
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.3 }}
                    className="font-outfit text-4xl md:text-5xl text-center mb-2 tracking-tight font-bold"
                  >
                    <span className="bg-gradient-to-r from-honey via-orange-400 to-honey bg-clip-text text-transparent">
                      Launching on Berachain in Q5
                    </span>
                  </motion.h2>
                  <div className="absolute inset-x-0 -bottom-8">
                    <SparklesCore
                      background="transparent"
                      minSize={0.4}
                      maxSize={1}
                      particleDensity={100}
                      className="w-full h-20"
                      particleColor="#FFFFFF"
                    />
                  </div>
                </div>

                {/* Whitelist Button */}
                <motion.button
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.4 }}
                  onClick={() => setShowForm(true)}
                  className="relative px-12 py-3.5 bg-gradient-to-r from-honey via-amber-500 to-honey bg-size-200 bg-pos-0 hover:bg-pos-100 text-white font-medium rounded-full transition-all duration-300 text-lg tracking-wide shadow-lg hover:shadow-honey/20 hover:-translate-y-0.5 mb-20"
                  style={{ backgroundSize: '200% auto' }}
                >
                  <span className="drop-shadow-[0_1.2px_1.2px_rgba(0,0,0,0.8)]">
                    Whitelist
                  </span>
                </motion.button>

                {/* Icons Row */}
                <motion.div 
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.5 }}
                  className="flex items-start justify-center gap-16"
                >
                  <div className="flex flex-col items-center group cursor-pointer" onClick={() => setShowBeradigmModal(true)}>
                    <div className="w-20 h-20 bg-black/80 backdrop-blur-xl rounded-3xl flex items-center justify-center mb-3 shadow-lg border border-honey/10 transition-all duration-300 group-hover:scale-105 group-hover:border-honey/30 group-hover:shadow-honey/20">
                      <Image
                        src="/beradigm.png"
                        alt="Beradigm"
                        width={48}
                        height={48}
                        className="rounded-2xl"
                      />
                    </div>
                    <span className="font-outfit text-base text-honey/80 group-hover:text-honey transition-colors duration-300">Beradigm</span>
                  </div>

                  <a 
                    href="https://twitter.com/baosdotfun" 
                    target="_blank" 
                    rel="noopener noreferrer" 
                    className="flex flex-col items-center group"
                  >
                    <div className="w-20 h-20 bg-black/80 backdrop-blur-xl rounded-3xl flex items-center justify-center mb-3 shadow-lg border border-honey/10 transition-all duration-300 group-hover:scale-105 group-hover:border-honey/30 group-hover:shadow-honey/20">
                      <Image
                        src="/baos_logo.png"
                        alt="Baos Logo"
                        width={48}
                        height={48}
                        className="rounded-2xl"
                      />
                    </div>
                    <span className="font-outfit text-base text-honey/80 group-hover:text-honey transition-colors duration-300">Baos</span>
                  </a>

                  <div className="flex flex-col items-center group cursor-pointer" onClick={() => setShowBElizaModal(true)}>
                    <div className="w-20 h-20 bg-black/80 backdrop-blur-xl rounded-3xl flex items-center justify-center mb-3 shadow-lg border border-honey/10 transition-all duration-300 group-hover:scale-105 group-hover:border-honey/30 group-hover:shadow-honey/20">
                      <div className="flex items-center gap-1 text-2xl">
                        <span>🐻</span>
                        <span>⚒️</span>
                      </div>
                    </div>
                    <span className="font-outfit text-base text-honey/80 group-hover:text-honey transition-colors duration-300">bEliza</span>
                  </div>
                </motion.div>

                {/* Modals */}
                <Modal
                  isOpen={showBeradigmModal}
                  onClose={() => setShowBeradigmModal(false)}
                  title="Beradigm"
                >
                  <p>
                    Beradigm is the first BAO (Bera Autistic Organization) on baos.fun. Its primary focus is farming Kodiak Liquidity pools on highly volatile pairs and trading memecoins on MemeSwap.
                  </p>
                </Modal>

                <Modal
                  isOpen={showBElizaModal}
                  onClose={() => setShowBElizaModal(false)}
                  title="bEliza - AI Agent Framework"
                >
                  <p>
                    bEliza is an OS AI agent framework that democratizes AI deployment on Berachain. It provides the infrastructure and tools needed for anyone to create and ship their own AI agents on the Berachain ecosystem.
                  </p>
                </Modal>
              </div>
            </motion.div>
          ) : (
            <motion.div
              key="form"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="min-h-screen flex items-center justify-center p-4"
            >
              <form onSubmit={handleSubmit} className="max-w-md w-full space-y-6 bg-black/80 p-8 rounded-xl backdrop-blur-sm border border-honey/10">
                <div className="text-center mb-8">
                  <button
                    type="button"
                    onClick={() => setShowForm(false)}
                    className="text-honey hover:text-honey-dark mb-4"
                  >
                    ← Back
                  </button>
                  <h2 className="font-outfit text-2xl bg-gradient-to-r from-honey via-amber-400 to-honey bg-clip-text text-transparent">BAO Whitelist</h2>
                </div>

                <div>
                  <label className="block text-sm font-medium mb-2">Telegram</label>
                  <input
                    type="text"
                    value={formData.telegram}
                    onChange={(e) => setFormData({ ...formData, telegram: e.target.value })}
                    className="w-full px-4 py-2 bg-gray-800/50 rounded-lg focus:ring-2 focus:ring-honey border border-honey/10"
                    required
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium mb-2">Twitter</label>
                  <input
                    type="text"
                    value={formData.twitter}
                    onChange={(e) => setFormData({ ...formData, twitter: e.target.value })}
                    className="w-full px-4 py-2 bg-gray-800/50 rounded-lg focus:ring-2 focus:ring-honey border border-honey/10"
                    required
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium mb-2">Wallet Address</label>
                  <input
                    type="text"
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    className="w-full px-4 py-2 bg-gray-800/50 rounded-lg focus:ring-2 focus:ring-honey border border-honey/10"
                    required
                  />
                </div>

                <button
                  type="submit"
                  className="w-full py-3 px-4 bg-honey hover:bg-honey-dark text-white font-medium rounded-lg transition-all duration-300 hover:shadow-lg hover:shadow-honey/20"
                >
                  Submit
                </button>
              </form>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </main>
  );
}
