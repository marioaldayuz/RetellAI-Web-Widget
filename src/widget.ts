import './styles.css';
import { RetellWebClient } from 'retell-client-js-sdk';

interface WidgetConfig {
  agentId: string;
  position?: 'bottom-right' | 'bottom-left' | 'top-right' | 'top-left';
  theme?: 'purple' | 'blue' | 'green';
  proxyEndpoint?: string;
}

interface CallState {
  isActive: boolean;
  startTime: number | null;
  isMuted: boolean;
  isSpeaking: boolean;
}

class RetellWidget {
  private config: WidgetConfig;
  private container: HTMLElement | null = null;
  private retellClient: RetellWebClient | null = null;
  private callState: CallState = {
    isActive: false,
    startTime: null,
    isMuted: false,
    isSpeaking: false
  };
  private timerInterval: number | null = null;

  constructor(config: WidgetConfig) {
    this.config = {
      position: 'bottom-right',
      theme: 'purple',
      proxyEndpoint: '/api/create-web-call', // Default to relative, but should be full URL for 3rd party sites
      ...config
    };
    this.init();
  }

  private init(): void {
    this.createWidget();
    this.setupEventListeners();
  }

  private createWidget(): void {
    // Remove existing widget if any
    const existing = document.getElementById('retell-widget');
    if (existing) {
      existing.remove();
    }

    // Create container
    this.container = document.createElement('div');
    this.container.id = 'retell-widget';
    this.container.className = 'retell-widget';
    
    // Set position styles
    const positionStyles = this.getPositionStyles();
    Object.assign(this.container.style, {
      position: 'fixed',
      zIndex: '999999',
      ...positionStyles
    });

    this.container.innerHTML = this.getWidgetHTML();
    document.body.appendChild(this.container);
  }

  private getPositionStyles(): Record<string, string> {
    const baseStyles = {
      margin: '20px'
    };

    switch (this.config.position) {
      case 'bottom-right':
        return { ...baseStyles, bottom: '0', right: '0' };
      case 'bottom-left':
        return { ...baseStyles, bottom: '0', left: '0' };
      case 'top-right':
        return { ...baseStyles, top: '0', right: '0' };
      case 'top-left':
        return { ...baseStyles, top: '0', left: '0' };
      default:
        return { ...baseStyles, bottom: '0', right: '0' };
    }
  }

  private getThemeColors(): Record<string, string> {
    const themes = {
      purple: {
        primary: '#9333ea',
        secondary: '#a855f7',
        accent: '#c084fc'
      },
      blue: {
        primary: '#2563eb',
        secondary: '#3b82f6',
        accent: '#60a5fa'
      },
      green: {
        primary: '#059669',
        secondary: '#10b981',
        accent: '#34d399'
      }
    };
    return themes[this.config.theme || 'purple'];
  }

  private getWidgetHTML(): string {
    const colors = this.getThemeColors();
    
    return `
      <div class="bg-gray-900/90 retell-widget-glassmorphism backdrop-blur-xl rounded-2xl shadow-2xl border border-white/10 p-4 min-w-[280px] retell-widget-fade-in">
        <!-- Header -->
        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center space-x-2">
            <div class="w-3 h-3 rounded-full" style="background: ${colors.primary}"></div>
            <span class="text-white font-medium text-sm">AI Assistant</span>
          </div>
          <button id="retell-close-btn" class="text-gray-400 hover:text-white transition-colors">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>

        <!-- Call Status -->
        <div id="retell-status" class="text-center mb-4">
          <div id="retell-idle-state">
            <div class="w-16 h-16 mx-auto mb-3 rounded-full flex items-center justify-center retell-widget-glassmorphism" 
                 style="background: linear-gradient(135deg, ${colors.primary}, ${colors.secondary})">
              <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path>
              </svg>
            </div>
            <p class="text-gray-300 text-sm mb-4">Ready to start a conversation</p>
          </div>

          <div id="retell-active-state" class="hidden">
            <div class="w-16 h-16 mx-auto mb-3 rounded-full flex items-center justify-center" 
                 style="background: linear-gradient(135deg, ${colors.primary}, ${colors.secondary})">
              <div id="retell-speech-indicator" class="flex items-center space-x-1">
                <div class="w-1 h-4 retell-widget-speech-bar rounded-full" style="background: white"></div>
                <div class="w-1 h-4 retell-widget-speech-bar rounded-full" style="background: white"></div>
                <div class="w-1 h-4 retell-widget-speech-bar rounded-full" style="background: white"></div>
                <div class="w-1 h-4 retell-widget-speech-bar rounded-full" style="background: white"></div>
              </div>
            </div>
            <div id="retell-timer" class="text-white font-mono text-lg mb-2">00:00</div>
            <p class="text-gray-300 text-sm mb-4">Call in progress...</p>
          </div>
        </div>

        <!-- Controls -->
        <div class="flex justify-center space-x-3">
          <button id="retell-call-btn" 
                  class="retell-widget-button px-6 py-3 rounded-xl font-medium text-white transition-all duration-300 shadow-lg"
                  style="background: linear-gradient(135deg, ${colors.primary}, ${colors.secondary})">
            <span id="retell-call-text">Start Call</span>
          </button>
          
          <button id="retell-mute-btn" 
                  class="retell-widget-button hidden px-4 py-3 rounded-xl bg-gray-700 hover:bg-gray-600 text-white transition-all duration-300">
            <svg id="retell-mute-icon" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"></path>
            </svg>
          </button>
        </div>

        <!-- Error Message -->
        <div id="retell-error" class="hidden mt-4 p-3 bg-red-500/20 border border-red-500/30 rounded-lg">
          <p class="text-red-300 text-sm text-center"></p>
        </div>
      </div>
    `;
  }

  private setupEventListeners(): void {
    if (!this.container) return;

    // Call button
    const callBtn = this.container.querySelector('#retell-call-btn') as HTMLButtonElement;
    callBtn?.addEventListener('click', () => {
      if (this.callState.isActive) {
        this.endCall();
      } else {
        this.startCall();
      }
    });

    // Mute button
    const muteBtn = this.container.querySelector('#retell-mute-btn') as HTMLButtonElement;
    muteBtn?.addEventListener('click', () => {
      this.toggleMute();
    });

    // Close button
    const closeBtn = this.container.querySelector('#retell-close-btn') as HTMLButtonElement;
    closeBtn?.addEventListener('click', () => {
      this.minimize();
    });
  }

  private async startCall(): Promise<void> {
    try {
      this.showLoading();
      
      // Call proxy server instead of Retell API directly
      const response = await fetch(this.config.proxyEndpoint!, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          agent_id: this.config.agentId
        })
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Failed to create web call');
      }

      const { access_token } = await response.json();

      // Initialize Retell client
      this.retellClient = new RetellWebClient();
      
      this.retellClient.on('call_started', () => {
        this.callState.isActive = true;
        this.callState.startTime = Date.now();
        this.updateUI();
        this.startTimer();
      });

      this.retellClient.on('call_ended', () => {
        this.endCall();
      });

      this.retellClient.on('agent_start_talking', () => {
        this.callState.isSpeaking = true;
        this.updateSpeechIndicator();
      });

      this.retellClient.on('agent_stop_talking', () => {
        this.callState.isSpeaking = false;
        this.updateSpeechIndicator();
      });

      this.retellClient.on('error', (error) => {
        this.showError('Call failed: ' + error.message);
        this.endCall();
      });

      // Start the call
      await this.retellClient.startCall({
        accessToken: access_token
      });

    } catch (error) {
      this.showError('Failed to start call: ' + (error as Error).message);
      this.hideLoading();
    }
  }

  private endCall(): void {
    if (this.retellClient) {
      this.retellClient.stopCall();
      this.retellClient = null;
    }

    this.callState.isActive = false;
    this.callState.startTime = null;
    this.callState.isMuted = false;
    this.callState.isSpeaking = false;

    if (this.timerInterval) {
      clearInterval(this.timerInterval);
      this.timerInterval = null;
    }

    this.updateUI();
  }

  private toggleMute(): void {
    if (!this.retellClient || !this.callState.isActive) return;

    this.callState.isMuted = !this.callState.isMuted;
    
    if (this.callState.isMuted) {
      this.retellClient.mute();
    } else {
      this.retellClient.unmute();
    }

    this.updateMuteButton();
  }

  private startTimer(): void {
    this.timerInterval = window.setInterval(() => {
      if (this.callState.startTime) {
        const elapsed = Math.floor((Date.now() - this.callState.startTime) / 1000);
        const minutes = Math.floor(elapsed / 60);
        const seconds = elapsed % 60;
        const timerElement = this.container?.querySelector('#retell-timer');
        if (timerElement) {
          timerElement.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        }
      }
    }, 1000);
  }

  private updateUI(): void {
    if (!this.container) return;

    const idleState = this.container.querySelector('#retell-idle-state');
    const activeState = this.container.querySelector('#retell-active-state');
    const callBtn = this.container.querySelector('#retell-call-btn') as HTMLButtonElement;
    const callText = this.container.querySelector('#retell-call-text');
    const muteBtn = this.container.querySelector('#retell-mute-btn');

    if (this.callState.isActive) {
      idleState?.classList.add('hidden');
      activeState?.classList.remove('hidden');
      muteBtn?.classList.remove('hidden');
      if (callText) callText.textContent = 'End Call';
      callBtn?.classList.add('bg-red-500', 'hover:bg-red-600');
    } else {
      idleState?.classList.remove('hidden');
      activeState?.classList.add('hidden');
      muteBtn?.classList.add('hidden');
      if (callText) callText.textContent = 'Start Call';
      callBtn?.classList.remove('bg-red-500', 'hover:bg-red-600');
    }

    this.updateMuteButton();
  }

  private updateMuteButton(): void {
    if (!this.container) return;

    const muteIcon = this.container.querySelector('#retell-mute-icon');
    if (!muteIcon) return;

    if (this.callState.isMuted) {
      muteIcon.innerHTML = `
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" clip-rule="evenodd"></path>
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2"></path>
      `;
    } else {
      muteIcon.innerHTML = `
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z"></path>
      `;
    }
  }

  private updateSpeechIndicator(): void {
    if (!this.container) return;

    const speechBars = this.container.querySelectorAll('.retell-widget-speech-bar');
    speechBars.forEach(bar => {
      if (this.callState.isSpeaking) {
        (bar as HTMLElement).style.animationPlayState = 'running';
      } else {
        (bar as HTMLElement).style.animationPlayState = 'paused';
      }
    });
  }

  private showLoading(): void {
    const callText = this.container?.querySelector('#retell-call-text');
    if (callText) callText.textContent = 'Connecting...';
  }

  private hideLoading(): void {
    const callText = this.container?.querySelector('#retell-call-text');
    if (callText) callText.textContent = 'Start Call';
  }

  private showError(message: string): void {
    if (!this.container) return;

    const errorElement = this.container.querySelector('#retell-error');
    const errorText = errorElement?.querySelector('p');
    
    if (errorElement && errorText) {
      errorText.textContent = message;
      errorElement.classList.remove('hidden');
      
      setTimeout(() => {
        errorElement.classList.add('hidden');
      }, 5000);
    }
  }

  private minimize(): void {
    if (this.container) {
      this.container.style.display = 'none';
    }
  }

  public show(): void {
    if (this.container) {
      this.container.style.display = 'block';
    }
  }

  public destroy(): void {
    if (this.callState.isActive) {
      this.endCall();
    }
    
    if (this.container) {
      this.container.remove();
      this.container = null;
    }
  }
}

// Make RetellWidget available globally
declare global {
  interface Window {
    RetellWidget: typeof RetellWidget;
    retellWidgetConfig?: WidgetConfig;
  }
}

// Expose RetellWidget globally
if (typeof window !== 'undefined') {
  window.RetellWidget = RetellWidget;
  
  // Auto-initialize if config is available
  if (window.retellWidgetConfig) {
    new RetellWidget(window.retellWidgetConfig);
  }
}

export default RetellWidget;
