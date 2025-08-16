import './styles.css';
import { RetellWebClient } from 'retell-client-js-sdk';

interface WidgetConfig {
  agentId: string;
  position?: 'bottom-right' | 'bottom-left' | 'top-right' | 'top-left';
  proxyEndpoint?: string;
  // New customization options
  primaryColor?: string;
  secondaryColor?: string;
  bubbleIcon?: string; // Font Awesome icon class (e.g., 'fa-headset', 'fa-message', 'fa-robot')
  welcomeMessage?: string;
  buttonLabel?: string;
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
  private bubble: HTMLElement | null = null;
  private retellClient: RetellWebClient | null = null;
  private isExpanded: boolean = false;
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
      proxyEndpoint: '/api/create-web-call',
      primaryColor: '#9333ea',
      secondaryColor: '#a855f7',
      bubbleIcon: 'fa-headset',
      welcomeMessage: 'How can I help you today?',
      buttonLabel: 'Start Conversation',
      ...config
    };
    this.init();
  }

  private init(): void {
    this.loadFontAwesome();
    this.createWidget();
    this.setupEventListeners();
  }

  private loadFontAwesome(): void {
    // Check if Font Awesome is already loaded
    if (!document.querySelector('link[href*="font-awesome"]') && !document.querySelector('link[href*="fontawesome"]')) {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css';
      document.head.appendChild(link);
    }
  }

  private createWidget(): void {
    // Remove existing widget if any
    const existing = document.getElementById('retell-widget-container');
    if (existing) {
      existing.remove();
    }

    // Create main container
    const mainContainer = document.createElement('div');
    mainContainer.id = 'retell-widget-container';
    mainContainer.className = 'retell-widget-container';
    
    // Set position styles
    const positionStyles = this.getPositionStyles();
    Object.assign(mainContainer.style, {
      position: 'fixed',
      zIndex: '999999',
      ...positionStyles
    });

    // Create chat bubble
    this.bubble = document.createElement('div');
    this.bubble.id = 'retell-bubble';
    this.bubble.className = 'retell-bubble';
    this.bubble.innerHTML = this.getBubbleHTML();
    
    // Create expanded window
    this.container = document.createElement('div');
    this.container.id = 'retell-widget';
    this.container.className = 'retell-widget retell-widget-hidden';
    this.container.innerHTML = this.getWidgetHTML();

    mainContainer.appendChild(this.bubble);
    mainContainer.appendChild(this.container);
    document.body.appendChild(mainContainer);

    // Apply custom colors
    this.applyCustomColors();
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

  private getBubbleHTML(): string {
    return `
      <button id="retell-bubble-btn" class="retell-bubble-button" aria-label="Open chat">
        <i class="fas ${this.config.bubbleIcon} retell-bubble-icon"></i>
        <span class="retell-bubble-badge"></span>
      </button>
    `;
  }

  private getWidgetHTML(): string {
    return `
      <div class="retell-widget-window">
        <!-- Header -->
        <div class="retell-widget-header">
          <div class="retell-widget-header-content">
            <div class="retell-widget-status-dot"></div>
            <span class="retell-widget-title">AI Assistant</span>
          </div>
          <div class="retell-widget-header-actions">
            <button id="retell-minimize-btn" class="retell-widget-header-btn" aria-label="Minimize">
              <i class="fas fa-minus"></i>
            </button>
            <button id="retell-close-btn" class="retell-widget-header-btn" aria-label="Close">
              <i class="fas fa-times"></i>
            </button>
          </div>
        </div>

        <!-- Content -->
        <div class="retell-widget-content">
          <!-- Welcome Message -->
          <div id="retell-welcome-message" class="retell-widget-message">
            ${this.config.welcomeMessage}
          </div>

          <!-- Main Button Area -->
          <div class="retell-widget-button-area">
            <!-- Microphone Button -->
            <button id="retell-call-btn" class="retell-widget-mic-button">
              <div id="retell-mic-icon" class="retell-widget-mic-icon">
                <i class="fas fa-microphone"></i>
              </div>
              <div id="retell-sound-waves" class="retell-widget-sound-waves retell-widget-hidden">
                <div class="sound-wave sound-wave-1"></div>
                <div class="sound-wave sound-wave-2"></div>
                <div class="sound-wave sound-wave-3"></div>
              </div>
            </button>
            
            <!-- Button Label -->
            <div id="retell-button-label" class="retell-widget-button-label">
              ${this.config.buttonLabel}
            </div>
          </div>

          <!-- Timer -->
          <div id="retell-timer-container" class="retell-widget-timer-container retell-widget-hidden">
            <div id="retell-timer" class="retell-widget-timer">00:00</div>
          </div>

          <!-- Mute Button -->
          <div id="retell-mute-container" class="retell-widget-mute-container retell-widget-hidden">
            <button id="retell-mute-btn" class="retell-widget-mute-btn">
              <i id="retell-mute-icon" class="fas fa-microphone"></i>
            </button>
          </div>

          <!-- Error Message -->
          <div id="retell-error" class="retell-widget-error retell-widget-hidden">
            <p id="retell-error-text"></p>
          </div>
        </div>
      </div>
    `;
  }

  private applyCustomColors(): void {
    const style = document.createElement('style');
    style.textContent = `
      :root {
        --retell-primary: ${this.config.primaryColor};
        --retell-secondary: ${this.config.secondaryColor};
      }
      .retell-bubble-button {
        background: linear-gradient(135deg, ${this.config.primaryColor}, ${this.config.secondaryColor});
      }
      .retell-widget-header {
        background: linear-gradient(135deg, ${this.config.primaryColor}, ${this.config.secondaryColor});
      }
      .retell-widget-mic-button {
        background: linear-gradient(135deg, ${this.config.primaryColor}, ${this.config.secondaryColor});
      }
      .retell-widget-mic-button:hover {
        background: linear-gradient(135deg, ${this.config.secondaryColor}, ${this.config.primaryColor});
      }
      .retell-widget-status-dot {
        background: #10b981;
      }
      .sound-wave {
        background: white;
      }
    `;
    document.head.appendChild(style);
  }

  private setupEventListeners(): void {
    // Bubble click
    const bubbleBtn = document.querySelector('#retell-bubble-btn');
    bubbleBtn?.addEventListener('click', () => {
      this.toggleWidget();
    });

    // Call button
    const callBtn = document.querySelector('#retell-call-btn');
    callBtn?.addEventListener('click', () => {
      if (this.callState.isActive) {
        this.endCall();
      } else {
        this.startCall();
      }
    });

    // Mute button
    const muteBtn = document.querySelector('#retell-mute-btn');
    muteBtn?.addEventListener('click', () => {
      this.toggleMute();
    });

    // Minimize button
    const minimizeBtn = document.querySelector('#retell-minimize-btn');
    minimizeBtn?.addEventListener('click', () => {
      this.toggleWidget();
    });

    // Close button
    const closeBtn = document.querySelector('#retell-close-btn');
    closeBtn?.addEventListener('click', () => {
      if (this.callState.isActive) {
        this.endCall();
      }
      this.toggleWidget();
    });
  }

  private toggleWidget(): void {
    this.isExpanded = !this.isExpanded;
    
    if (this.isExpanded) {
      this.bubble?.classList.add('retell-bubble-hidden');
      this.container?.classList.remove('retell-widget-hidden');
      this.container?.classList.add('retell-widget-visible');
    } else {
      this.bubble?.classList.remove('retell-bubble-hidden');
      this.container?.classList.remove('retell-widget-visible');
      this.container?.classList.add('retell-widget-hidden');
    }
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
        const timerElement = document.querySelector('#retell-timer');
        if (timerElement) {
          timerElement.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        }
      }
    }, 1000);
  }

  private updateUI(): void {
    const welcomeMessage = document.querySelector('#retell-welcome-message');
    const buttonLabel = document.querySelector('#retell-button-label');
    const timerContainer = document.querySelector('#retell-timer-container');
    const muteContainer = document.querySelector('#retell-mute-container');
    const micIcon = document.querySelector('#retell-mic-icon');
    const soundWaves = document.querySelector('#retell-sound-waves');
    const callBtn = document.querySelector('#retell-call-btn');

    if (this.callState.isActive) {
      welcomeMessage?.classList.add('retell-widget-hidden');
      timerContainer?.classList.remove('retell-widget-hidden');
      muteContainer?.classList.remove('retell-widget-hidden');
      
      if (buttonLabel) {
        (buttonLabel as HTMLElement).textContent = 'End Call';
      }
      
      callBtn?.classList.add('retell-widget-mic-button-active');
      
      // Show sound waves when speaking
      if (this.callState.isSpeaking) {
        micIcon?.classList.add('retell-widget-hidden');
        soundWaves?.classList.remove('retell-widget-hidden');
      } else {
        micIcon?.classList.remove('retell-widget-hidden');
        soundWaves?.classList.add('retell-widget-hidden');
      }
    } else {
      welcomeMessage?.classList.remove('retell-widget-hidden');
      timerContainer?.classList.add('retell-widget-hidden');
      muteContainer?.classList.add('retell-widget-hidden');
      micIcon?.classList.remove('retell-widget-hidden');
      soundWaves?.classList.add('retell-widget-hidden');
      
      if (buttonLabel) {
        (buttonLabel as HTMLElement).textContent = this.config.buttonLabel || 'Start Conversation';
      }
      
      callBtn?.classList.remove('retell-widget-mic-button-active');
    }

    this.updateMuteButton();
  }

  private updateMuteButton(): void {
    const muteIcon = document.querySelector('#retell-mute-icon');
    const muteBtn = document.querySelector('#retell-mute-btn');
    
    if (!muteIcon || !muteBtn) return;

    if (this.callState.isMuted) {
      muteIcon.className = 'fas fa-microphone-slash';
      muteBtn.classList.add('retell-widget-mute-btn-muted');
    } else {
      muteIcon.className = 'fas fa-microphone';
      muteBtn.classList.remove('retell-widget-mute-btn-muted');
    }
  }

  private updateSpeechIndicator(): void {
    const micIcon = document.querySelector('#retell-mic-icon');
    const soundWaves = document.querySelector('#retell-sound-waves');

    if (this.callState.isActive) {
      if (this.callState.isSpeaking) {
        micIcon?.classList.add('retell-widget-hidden');
        soundWaves?.classList.remove('retell-widget-hidden');
      } else {
        micIcon?.classList.remove('retell-widget-hidden');
        soundWaves?.classList.add('retell-widget-hidden');
      }
    }
  }

  private showLoading(): void {
    const buttonLabel = document.querySelector('#retell-button-label');
    if (buttonLabel) {
      (buttonLabel as HTMLElement).textContent = 'Connecting...';
    }
  }

  private hideLoading(): void {
    const buttonLabel = document.querySelector('#retell-button-label');
    if (buttonLabel) {
      (buttonLabel as HTMLElement).textContent = this.config.buttonLabel || 'Start Conversation';
    }
  }

  private showError(message: string): void {
    const errorElement = document.querySelector('#retell-error');
    const errorText = document.querySelector('#retell-error-text');
    
    if (errorElement && errorText) {
      (errorText as HTMLElement).textContent = message;
      errorElement.classList.remove('retell-widget-hidden');
      
      setTimeout(() => {
        errorElement.classList.add('retell-widget-hidden');
      }, 5000);
    }
  }

  public show(): void {
    this.toggleWidget();
  }

  public destroy(): void {
    if (this.callState.isActive) {
      this.endCall();
    }
    
    const container = document.querySelector('#retell-widget-container');
    if (container) {
      container.remove();
    }
    
    this.container = null;
    this.bubble = null;
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