import React, { useState, useEffect, useRef } from 'react';
import { Phone, PhoneOff, Mic, MicOff } from 'lucide-react';
import { RetellWebClient } from 'retell-client-js-sdk';

interface RetellWidgetProps {
  apiKey?: string;
  agentId?: string;
}

const RetellWidget: React.FC<RetellWidgetProps> = ({ 
  apiKey = 'key_f741045b4d6546daad117e5ebd5b', 
  agentId = 'agent_1dc973641c277176a5b941595d' 
}) => {
  const [isCallActive, setIsCallActive] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);
  const [callDuration, setCallDuration] = useState(0);
  const [isSpeaking, setIsSpeaking] = useState(false);
  const [isMuted, setIsMuted] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const retellClientRef = useRef<RetellWebClient | null>(null);
  const callStartTimeRef = useRef<number | null>(null);
  const timerIntervalRef = useRef<NodeJS.Timeout | null>(null);

  // Initialize Retell client
  useEffect(() => {
    try {
      retellClientRef.current = new RetellWebClient();
      
      // Set up event listeners
      retellClientRef.current.on('call_started', () => {
        setIsCallActive(true);
        setIsConnecting(false);
        callStartTimeRef.current = Date.now();
        startTimer();
      });

      retellClientRef.current.on('call_ended', () => {
        setIsCallActive(false);
        setIsConnecting(false);
        setIsSpeaking(false);
        stopTimer();
        setCallDuration(0);
      });

      retellClientRef.current.on('agent_start_talking', () => {
        setIsSpeaking(true);
      });

      retellClientRef.current.on('agent_stop_talking', () => {
        setIsSpeaking(false);
      });

      retellClientRef.current.on('error', (error) => {
        console.error('Retell error:', error);
        setError('Call failed. Please try again.');
        setIsConnecting(false);
        setIsCallActive(false);
      });

    } catch (err) {
      console.error('Failed to initialize Retell client:', err);
      setError('Failed to initialize call system');
    }

    return () => {
      if (retellClientRef.current) {
        retellClientRef.current.stopCall();
      }
      stopTimer();
    };
  }, []);

  const startTimer = () => {
    timerIntervalRef.current = setInterval(() => {
      if (callStartTimeRef.current) {
        const elapsed = Math.floor((Date.now() - callStartTimeRef.current) / 1000);
        setCallDuration(elapsed);
      }
    }, 1000);
  };

  const stopTimer = () => {
    if (timerIntervalRef.current) {
      clearInterval(timerIntervalRef.current);
      timerIntervalRef.current = null;
    }
    callStartTimeRef.current = null;
  };

  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const startCall = async () => {
    if (!retellClientRef.current) return;
    
    setIsConnecting(true);
    setError(null);
    
    try {
      // In a real implementation, you'd call your backend to create a web call
      // and get the access token. For demo purposes, we'll simulate this.
      const response = await fetch('/api/create-web-call', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          agent_id: agentId,
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to create call');
      }

      const { access_token } = await response.json();
      
      await retellClientRef.current.startCall({
        accessToken: access_token,
      });
    } catch (err) {
      console.error('Failed to start call:', err);
      setError('Failed to start call. Please check your configuration.');
      setIsConnecting(false);
    }
  };

  const endCall = () => {
    if (retellClientRef.current) {
      retellClientRef.current.stopCall();
    }
  };

  const toggleMute = () => {
    if (retellClientRef.current && isCallActive) {
      if (isMuted) {
        retellClientRef.current.unmute();
      } else {
        retellClientRef.current.mute();
      }
      setIsMuted(!isMuted);
    }
  };

  return (
    <div className="fixed bottom-6 right-6 z-50">
      <div className="bg-gradient-to-br from-purple-600 via-purple-700 to-indigo-800 rounded-2xl shadow-2xl p-6 w-72 backdrop-blur-sm border border-purple-400/20">
        {/* Header */}
        <div className="text-center mb-6">
          <h3 className="text-white font-semibold text-lg mb-1">AI Assistant</h3>
          <p className="text-purple-200 text-sm">Ready to help you</p>
        </div>

        {/* Visual Speech Indicator */}
        {isCallActive && (
          <div className="flex justify-center mb-6">
            <div className="flex space-x-1">
              {[...Array(5)].map((_, i) => (
                <div
                  key={i}
                  className={`w-1 bg-gradient-to-t from-pink-400 to-purple-300 rounded-full transition-all duration-150 ${
                    isSpeaking 
                      ? `h-${4 + (i % 3) * 2} animate-pulse` 
                      : 'h-2'
                  }`}
                  style={{
                    animationDelay: `${i * 100}ms`,
                    height: isSpeaking ? `${16 + Math.sin(Date.now() / 200 + i) * 8}px` : '8px'
                  }}
                />
              ))}
            </div>
          </div>
        )}

        {/* Call Timer */}
        {isCallActive && (
          <div className="text-center mb-6">
            <div className="bg-black/20 rounded-lg px-4 py-2 backdrop-blur-sm">
              <span className="text-white font-mono text-xl tracking-wider">
                {formatTime(callDuration)}
              </span>
            </div>
          </div>
        )}

        {/* Error Message */}
        {error && (
          <div className="bg-red-500/20 border border-red-400/30 rounded-lg p-3 mb-4">
            <p className="text-red-200 text-sm text-center">{error}</p>
          </div>
        )}

        {/* Main Action Button */}
        <div className="flex justify-center mb-4">
          {!isCallActive ? (
            <button
              onClick={startCall}
              disabled={isConnecting}
              className={`w-16 h-16 rounded-full flex items-center justify-center transition-all duration-300 transform hover:scale-110 ${
                isConnecting
                  ? 'bg-yellow-500 animate-pulse cursor-not-allowed'
                  : 'bg-gradient-to-r from-green-400 to-green-600 hover:from-green-500 hover:to-green-700 shadow-lg hover:shadow-green-500/25'
              }`}
            >
              <Phone className="w-6 h-6 text-white" />
            </button>
          ) : (
            <div className="flex space-x-3">
              {/* Mute Button */}
              <button
                onClick={toggleMute}
                className={`w-12 h-12 rounded-full flex items-center justify-center transition-all duration-300 ${
                  isMuted
                    ? 'bg-red-500 hover:bg-red-600'
                    : 'bg-gray-600 hover:bg-gray-700'
                } shadow-lg`}
              >
                {isMuted ? (
                  <MicOff className="w-5 h-5 text-white" />
                ) : (
                  <Mic className="w-5 h-5 text-white" />
                )}
              </button>

              {/* End Call Button */}
              <button
                onClick={endCall}
                className="w-16 h-16 rounded-full bg-gradient-to-r from-red-500 to-red-600 hover:from-red-600 hover:to-red-700 flex items-center justify-center transition-all duration-300 transform hover:scale-110 shadow-lg hover:shadow-red-500/25"
              >
                <PhoneOff className="w-6 h-6 text-white" />
              </button>
            </div>
          )}
        </div>

        {/* Status Text */}
        <div className="text-center">
          <p className="text-purple-200 text-sm">
            {isConnecting ? 'Connecting...' : 
             isCallActive ? 'Call in progress' : 
             'Click to start call'}
          </p>
        </div>

        {/* Pulse Animation Ring */}
        {(isConnecting || isCallActive) && (
          <div className="absolute inset-0 rounded-2xl">
            <div className="absolute inset-0 rounded-2xl bg-purple-400/20 animate-ping" />
            <div className="absolute inset-2 rounded-xl bg-purple-400/10 animate-ping animation-delay-75" />
          </div>
        )}
      </div>
    </div>
  );
};

export default RetellWidget;
